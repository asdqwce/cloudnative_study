---
layout: default
---

<div class="badge"><span class="num">04</span><span class="label">지도</span></div>

# 전체를 한 번에 보면 이렇게 나뉩니다

<img :src="'/architecture.png'" alt="MediKong overview architecture" class="diagram-img wide" />

<div class="lede" style="margin-top: 20px;">
한 장으로 모든 세부를 설명하지 않고, 로컬 검증, 런타임, AWS 릴리스를 나눠서 보겠습니다.
</div>

<!--
이 그림은 전체 설명의 지도 역할입니다.
왼쪽은 로컬에서 구조를 검증하는 부분이고, 가운데는 실제 의료 서비스 런타임입니다.
오른쪽은 이미지와 manifest를 AWS 쪽으로 보내는 릴리스 흐름입니다.
세부 구조는 지금부터 한 장씩 분리해서 보겠습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">05</span><span class="label">AWS</span></div>

# AWS 인프라는 무엇을 준비하나

<div class="diagram-slide">
  <img :src="'/aws-infra.png'" alt="AWS infrastructure diagram" />
  <div class="diagram-notes">
    <div class="point"><strong>계정과 권한</strong><span>GitHub OIDC, release role, worker instance profile을 분리합니다.</span></div>
    <div class="point"><strong>실행 노드</strong><span>EC2 master 1대와 worker 2대가 self-managed Kubernetes를 구성합니다.</span></div>
    <div class="point"><strong>이미지 저장소</strong><span>서비스별 Private ECR repository를 `ap-northeast-2`에 둡니다.</span></div>
  </div>
</div>

<!--
AWS 쪽에서 먼저 볼 것은 서버보다 권한입니다.
GitHub Actions는 OIDC로 릴리스 role을 assume하고, worker node는 별도 instance profile로 ECR pull 권한을 갖습니다.
EC2는 master 하나와 worker 둘로 시작하고, 서비스 이미지는 모두 서울 리전의 Private ECR로 보냅니다.
-->

---
layout: default
---

<div class="badge"><span class="num">05-1</span><span class="label">Terraform</span></div>

# 그래서 Terraform은 이 경계를 만든다

<div class="split">
<div class="small-code">
<div class="source-label">source: terraform/main.tf</div>

```hcl
resource "aws_instance" "master" {
  instance_type          = "r6g.large"
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
}

resource "aws_instance" "worker" {
  count                = 2
  instance_type        = "r6g.medium"
  iam_instance_profile = aws_iam_instance_profile.worker_node.name
}
```
</div>
<div class="small-code">
<div class="source-label">source: terraform/ecr.tf, terraform/iam.tf</div>

```hcl
resource "aws_ecr_repository" "service" {
  for_each = local.ecr_repository_names
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_iam_role" "github_actions_release" {
  assume_role_policy = jsonencode(...)
}
```
</div>
</div>

<!--
방금 그림을 코드로 옮긴 부분입니다.
Terraform은 EC2와 Security Group만 만드는 게 아니라, release role과 worker pull role, 서비스별 ECR repository까지 같이 만듭니다.
worker에 instance profile을 붙이는 이유는 나중에 Kubernetes 노드가 Private ECR 이미지를 당겨와야 하기 때문입니다.
-->

---
layout: default
---

<div class="badge"><span class="num">06</span><span class="label">K8s</span></div>

# Kubernetes는 로컬과 AWS를 같은 개념으로 맞춘다

<div class="diagram-slide">
  <img :src="'/kubernetes-cluster.png'" alt="Kubernetes cluster diagram" />
  <div class="diagram-notes">
    <div class="point"><strong>로컬</strong><span>VMware/Vagrant, local registry, MetalLB, Kong으로 운영 문제를 먼저 확인합니다.</span></div>
    <div class="point"><strong>클러스터 내부</strong><span>Ingress, namespace, NetworkPolicy, 서비스별 DB와 Kafka가 핵심입니다.</span></div>
    <div class="point"><strong>AWS</strong><span>EC2 Kubernetes는 Private ECR pull과 Argo CD sync를 이어받습니다.</span></div>
  </div>
</div>

<!--
로컬과 AWS가 완전히 같은 환경은 아닙니다.
다만 중요한 운영 개념은 맞췄습니다.
로컬에서는 local registry와 MetalLB로 image pull과 LoadBalancer를 확인하고, AWS에서는 Private ECR과 Argo CD가 그 역할을 이어받습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">06-1</span><span class="label">로컬</span></div>

# 로컬 클러스터는 단순 실행 환경이 아닙니다

```text
VMware + Vagrant
├─ control-plane-1  10.10.10.10
├─ worker-1         10.10.10.11
└─ worker-2         10.10.10.12

Kubernetes
├─ local registry   10.10.10.10:5000
├─ MetalLB          10.10.10.240-10.10.10.250
└─ Kong Gateway     http://10.10.10.240
```

<div class="lede" style="margin-top: 24px;">
Docker Compose보다 무겁지만, 실제 배포에서 만나는 네트워크와 image pull 문제를 먼저 드러냅니다.
</div>

<!--
로컬 검증을 Docker Compose만으로 끝내지 않은 이유가 여기 있습니다.
VM 위의 Kubernetes는 준비가 조금 번거롭지만, LoadBalancer IP, local registry, Ingress, node image pull 같은 문제를 실제처럼 확인할 수 있습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">07</span><span class="label">런타임</span></div>

# 서비스 런타임은 Kong에서 시작합니다

<div class="split">
<div>
<div class="mini-title">요청 경로</div>

- Browser → Kong LoadBalancer
- Kong Ingress → FastAPI 서비스
- JWT plugin이 인증을 확인
- identity header로 서비스에 사용자 맥락 전달
</div>
<div>
<div class="mini-title">데이터 경로</div>

- 환자, 예약, 처방, 알림 DB 분리
- 예약 확정: `appointment-confirmed`
- 처방 발행: `prescription-issued`
- 알림 서비스가 Kafka 이벤트를 소비
</div>
</div>

<!--
런타임 관점에서는 Kong이 외부 진입점입니다.
요청은 Kong을 거쳐 각 FastAPI 서비스로 가고, 인증 정보는 JWT와 header 흐름으로 전달됩니다.
데이터는 서비스별 DB에 남기고, 상태 전파가 필요한 부분만 Kafka 이벤트로 흘립니다.
-->

---
layout: default
---

<div class="badge"><span class="num">08</span><span class="label">스택</span></div>

# 기술 스택은 역할별로 골랐습니다

<div class="tech-grid">
  <div class="tech">Python / FastAPI<small>서비스 API와 업무 로직</small></div>
  <div class="tech">PostgreSQL<small>서비스별 독립 DB</small></div>
  <div class="tech">Kafka<small>예약·처방 이벤트 전달</small></div>
  <div class="tech">Kong Gateway<small>라우팅, JWT, Rate Limit</small></div>
  <div class="tech">Kubernetes<small>Deployment, Service, Ingress</small></div>
  <div class="tech">VMware / Vagrant<small>로컬 kubeadm 클러스터</small></div>
  <div class="tech">Terraform / Ansible<small>AWS 리소스와 노드 bootstrap</small></div>
  <div class="tech">GitHub Actions<small>CI, E2E, 보안, 릴리스</small></div>
  <div class="tech">Argo CD<small>Git manifest sync</small></div>
  <div class="tech">Trivy / gitleaks<small>이미지와 secret 검증</small></div>
  <div class="tech">Newman / pytest<small>E2E와 단위 테스트</small></div>
  <div class="tech">Prometheus / Grafana<small>관측성 기반 준비</small></div>
</div>

<!--
스택은 크게 네 층입니다.
서비스는 FastAPI, 데이터는 PostgreSQL과 Kafka, 실행 환경은 Kubernetes와 Kong, 자동화는 GitHub Actions와 Argo CD가 맡습니다.
각 도구를 하나씩 설명하기보다, 어디에 놓였는지를 기억해 주시면 뒤쪽 코드와 workflow가 더 잘 보입니다.
-->
