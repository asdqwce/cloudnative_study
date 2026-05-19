# Release Environment Strategy

이 문서는 실습용 AWS Kubernetes 환경에서 릴리즈 브랜치, Git tag, image tag, namespace 기반 환경 분리를 어떻게 가져갈지 정리한다.

목표는 프로덕션 수준의 개념을 경험하되, 인프라 비용을 낮추기 위해 EC2 3대의 단일 Kubernetes 클러스터 안에서 `dev`와 `prod`를 구분하는 것이다.

## 결정 요약

- 애플리케이션 소스의 정본은 `main`이다.
- 릴리즈 버전은 브랜치가 아니라 Git tag로 관리한다.
- Docker image tag는 Git tag와 같은 값을 사용한다.
- 환경별 배포 상태는 `release/dev`, `release/prod` 브랜치에 둔다.
- 단일 클러스터 안에서 namespace, ingress host, quota, network policy로 `dev`와 `prod`를 분리한다.
- AWS 여부는 브랜치명에 넣지 않고, Kustomize overlay와 Argo CD Application 설정에서 표현한다.
- AWS image registry는 `ap-northeast-2` Private ECR을 사용하고, EC2 Kubernetes 클러스터 리전과 맞춘다.

## 브랜치와 태그의 역할

브랜치와 태그는 역할이 다르다.

| 대상 | 예시 | 역할 |
| --- | --- | --- |
| 소스 브랜치 | `main` | 애플리케이션 코드의 정본 |
| 작업 브랜치 | `feature/*`, `fix/*`, `docs/*` | 기능, 수정, 문서 작업 |
| 버전 태그 | `v1.2.3` | 불변 릴리즈 버전 |
| 이미지 태그 | `patient-service:v1.2.3` | 배포할 컨테이너 이미지 버전 |
| 환경 브랜치 | `release/dev`, `release/prod` | 각 환경의 GitOps manifest 상태 |

`release/dev`와 `release/prod`는 코드를 오래 분기하기 위한 브랜치가 아니다. 각 환경이 현재 어떤 image tag를 바라보는지 기록하는 배포 상태 브랜치다.

## 기본 릴리즈 흐름

```text
feature/*
-> main merge
-> Git tag 생성: v1.2.3
-> image build/push: service:v1.2.3
-> release/dev manifest를 v1.2.3으로 갱신
-> dev 검증
-> release/prod manifest를 v1.2.3으로 승격
-> Argo CD가 prod namespace에 sync
```

예를 들어 같은 클러스터 안에서도 환경마다 다른 버전을 바라볼 수 있다.

```text
release/dev  -> patient-service:v1.2.4-rc.1
release/prod -> patient-service:v1.2.3
```

`latest`, `dev`, `prod` 같은 mutable image tag는 배포 기준으로 사용하지 않는다. 같은 tag가 다른 image digest를 가리키면 롤백, 감사, 장애 분석이 어려워진다.

ECR repository는 서비스별로 나누고 이름은 `cloudnative-study/<service>` 형태를 쓴다. Git에는 Private ECR image URI와 Git tag 값만 남기며, AWS key, ECR token, kubeconfig, `.env`, `terraform.tfvars` 같은 secret은 남기지 않는다.

실무형 추적을 위해 image에는 두 가지 tag를 같이 붙일 수 있다.

```text
patient-service:v1.2.3
patient-service:sha-a1b2c3d
```

`v1.2.3`은 사람이 읽는 릴리즈 버전이고, `sha-a1b2c3d`는 정확한 빌드 추적용이다.

## 단일 클러스터 환경 분리

실습에서는 EC2 3대의 단일 Kubernetes 클러스터를 사용한다. 비용을 줄이면서도 운영에서 필요한 환경 분리 개념을 연습하기 위해 namespace와 ingress host를 나눈다.

```text
single AWS Kubernetes cluster
├─ namespace: medical-platform-dev
│  ├─ dev service
│  ├─ dev config/secret
│  └─ host: dev.example.com
│
├─ namespace: medical-platform-prod
│  ├─ prod service
│  ├─ prod config/secret
│  └─ host: api.example.com
│
└─ namespace: argocd, ingress, monitoring
```

Argo CD Application도 환경별로 분리한다.

```text
app-dev  -> release/dev  -> k8s/overlays/aws/dev  -> medical-platform-dev
app-prod -> release/prod -> k8s/overlays/aws/prod -> medical-platform-prod
```

Argo CD는 Git manifest를 sync할 뿐 Private ECR에 직접 로그인하지 않는다. 실제 image pull은 worker node의 kubelet/containerd가 수행하므로, EC2 self-managed Kubernetes에서는 worker instance profile의 ECR pull 권한과 kubelet image credential provider 구성을 함께 준비한다. `imagePullSecrets`는 ECR token 만료 때문에 임시 검증 수단으로만 둔다.

Ingress와 Load Balancer는 비용과 격리 수준에 따라 선택한다.

| 방식 | 구조 | 장점 | 단점 |
| --- | --- | --- | --- |
| 공유 LB | 하나의 ALB/Ingress에서 host 기반 라우팅 | 비용이 낮고 실습에 적합 | dev와 prod의 외부 진입점이 같은 LB에 묶임 |
| 환경별 LB | dev/prod Ingress 또는 ALB 분리 | 운영 경계가 더 명확함 | 비용 증가 |

실습 기본값은 공유 LB로 두고, prod 격리를 더 강조하고 싶을 때 환경별 LB로 확장한다.

## 필요한 격리 장치

namespace만으로 강한 프로덕션 격리가 완성되지는 않는다. 단일 클러스터 안에서 환경을 나누려면 다음 장치를 같이 둔다.

| 장치 | 목적 |
| --- | --- |
| Namespace | dev/prod 리소스의 기본 스코프 분리 |
| RBAC | dev 사용자가 prod 리소스를 수정하지 못하게 제한 |
| ResourceQuota | dev workload가 prod 자원을 과도하게 압박하지 못하게 제한 |
| LimitRange | Pod/container 기본 request/limit 강제 |
| NetworkPolicy | namespace 간 불필요한 통신 차단 |
| Secret 분리 | dev/prod credential 혼용 방지 |
| Argo CD App 분리 | 환경별 sync 상태와 rollback 경계 분리 |
| Branch protection | `release/prod` 변경 승인과 force push 금지 |

이 구성은 비용 절감형 실습 환경으로는 충분히 의미가 있다. 다만 실제 고객 트래픽을 받는 프로덕션에서는 dev 장애가 같은 클러스터의 prod 자원에 영향을 줄 수 있으므로, 나중에는 prod 클러스터 분리를 검토한다.

## 권장 네이밍

초기 AWS 단일 클러스터 실습에서는 브랜치명에 `aws`를 넣지 않는다.

```text
main
feature/*
fix/*
docs/*
release/dev
release/prod
v1.2.3
```

AWS는 브랜치명이 아니라 다음 위치에서 표현한다.

```text
k8s/overlays/aws/dev
k8s/overlays/aws/prod
infra/cluster/gitops/argocd/applications/app-dev.yaml
infra/cluster/gitops/argocd/applications/app-prod.yaml
terraform/
infra/cluster/provision/ansible/inventories/aws/dev.ini
```

멀티 클라우드를 실제로 운영하게 되면 그때 브랜치 네이밍을 확장한다.

```text
release/aws/dev
release/aws/prod
release/gcp/dev
release/gcp/prod
```

현재 실습 단계에서는 `release/dev`, `release/prod`가 더 단순하고 의도가 분명하다.

## 현재 레포 구조

현재 AWS GitOps 골격은 단일 물리 클러스터 안에서 dev/prod를 GitOps 환경으로 나누는 구조다. 클러스터를 두 개로 만들지 않고, 릴리즈 브랜치와 Kustomize overlay, namespace를 서로 맞춘다.

- `release/dev`는 `k8s/overlays/aws/dev`를 갱신하고 `medical-platform-dev` namespace로 sync한다.
- `release/prod`는 `k8s/overlays/aws/prod`를 갱신하고 `medical-platform-prod` namespace로 sync한다.
- Argo CD Application manifest는 `infra/cluster/gitops/argocd/applications`에 둔다.
- Argo CD AppProject는 dev/prod namespace만 destination으로 허용한다.
- dev Application은 자동 sync를 켜고, prod Application은 초기 실습에서는 수동 sync로 둔다.
- release workflow는 Git tag 기반 image를 ECR에 push하고 대상 release branch의 overlay manifest만 갱신한다.
- GitHub Actions는 클러스터에 `kubectl apply`를 직접 실행하지 않는다.

`release/prod`에는 branch protection, 승인 절차, force push 금지를 붙이는 것이 다음 운영 안전장치다. 실제 고객 트래픽을 받는 prod 격리가 필요해지면 이 구조를 유지한 채 prod 전용 클러스터로 destination만 확장한다.
