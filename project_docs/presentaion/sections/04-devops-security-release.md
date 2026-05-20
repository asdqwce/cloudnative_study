---
layout: default
---

<div class="badge"><span class="num">11</span><span class="label">테스트</span></div>

# 테스트 자동화는 두 층으로 나눴습니다

<div class="diagram-slide">
  <img :src="'/test-automation.png'" alt="Test automation diagram" />
  <div class="diagram-notes">
    <div class="point"><strong>단위 테스트</strong><span>Docker Python 테스트 러너 안에서 서비스별 pytest를 실행합니다.</span></div>
    <div class="point"><strong>E2E</strong><span>Compose 네트워크에 DB, Kafka, 서비스를 띄우고 Newman이 흐름을 검증합니다.</span></div>
    <div class="point"><strong>CI</strong><span>GitHub Actions도 로컬과 같은 Make target을 호출합니다.</span></div>
  </div>
</div>

<!--
테스트 자동화는 단위 테스트와 E2E를 분리했습니다.
단위 테스트는 Python 라이브러리를 로컬에 설치하지 않고 Docker 테스트 러너로 실행합니다.
E2E는 PostgreSQL, Kafka, FastAPI 서비스들을 같은 Compose 네트워크에 띄워서, 서비스 이름 기반 통신까지 같이 확인합니다.
-->

---
layout: default
---

<div class="badge"><span class="num">11-1</span><span class="label">Unit</span></div>

# 단위 테스트는 Docker만 있으면 같은 방식으로 돕니다

<div class="split">
<div class="small-code">
<div class="source-label">source: Makefile</div>

```make
test-runner-build:
	docker build -f tests/docker/Dockerfile \
	  -t $(TEST_RUNNER_IMAGE) .

test-unit: test-runner-build
	docker run --rm \
	  -v "$(CURDIR)":/workspace \
	  -w /workspace $(TEST_RUNNER_IMAGE) \
	  sh -c '... python -m pytest ...'
```
</div>
<div class="small-code">
<div class="source-label">source: .github/workflows/ci.yml</div>

```yaml
jobs:
  pytest:
    name: Docker pytest
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests in Docker
        run: make test-unit
```
</div>
</div>

<!--
단위 테스트를 Docker 러너로 돌린 이유는 단순합니다.
개발자 PC마다 Python 버전과 라이브러리 상태가 달라지면 테스트 결과도 흔들립니다.
그래서 `make test-unit`이 테스트용 이미지를 먼저 만들고, 현재 소스 트리를 컨테이너에 마운트해 같은 방식으로 pytest를 실행합니다.
CI도 이 흐름을 그대로 씁니다.
-->

---
layout: default
---

<div class="badge"><span class="num">11-2</span><span class="label">E2E</span></div>

# E2E는 서비스 간 경계를 실제처럼 확인합니다

<div class="split">
<div class="small-code">
<div class="source-label">source: tests/e2e/docker-compose.yml</div>

```yaml
services:
  postgres:
    image: postgres:16-alpine
  kafka:
    image: apache/kafka:3.8.1
  patient-service:
    build:
      context: ../../services/patient-service
  appointment-service:
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka:29092
```
</div>
<div>
<div class="mini-title">검증 흐름</div>

- `patient-service`에 환자 생성
- `appointment-service`에서 예약 요청과 확정
- `notification-service`가 예약 알림 저장
- `prescription-service`에서 처방 발행
- 알림과 처방을 환자 권한으로 조회
</div>
</div>

<!--
E2E는 단순히 함수를 부르는 테스트가 아닙니다.
PostgreSQL, Kafka, FastAPI 서비스들을 같은 Docker Compose 네트워크에 띄우고, Newman이 Postman collection을 실행합니다.
서비스 URL도 `patient-service:8081`처럼 Compose DNS 이름을 쓰기 때문에 네트워크 경계까지 같이 확인됩니다.
-->

---
layout: default
---

<div class="badge"><span class="num">12</span><span class="label">보안</span></div>

# 보안 검증은 노출 위치별로 끊었습니다

<div class="diagram-slide">
  <img :src="'/security-gates.png'" alt="Security gate diagram" />
  <div class="diagram-notes">
    <div class="point"><strong>pre-push / source gate</strong><span>secret, build context, Dockerfile lint를 source 단계에서 봅니다.</span></div>
    <div class="point"><strong>release image gate</strong><span>이미지를 만든 뒤 ECR push 전에 Trivy와 history를 봅니다.</span></div>
    <div class="point"><strong>경계</strong><span>repo 노출 방지와 registry 노출 방지를 같은 문제로 섞지 않았습니다.</span></div>
  </div>
</div>

<!--
보안 검증은 한 번에 다 막겠다는 식으로 설명하면 흐려집니다.
먼저 public repo에 올라가면 안 되는 것을 source gate에서 막고, 그 다음 image layer나 history에 남을 수 있는 것은 ECR push 전에 막습니다.
그래서 pre-push, security workflow, release workflow의 역할이 나뉩니다.
-->

---
layout: default
---

<div class="badge"><span class="num">12-1</span><span class="label">Source</span></div>

# source gate는 push 전에 걸립니다

<div class="split">
<div class="small-code">
<div class="source-label">source: scripts/security/pre-push.sh</div>

```sh
secret_scan() {
  "$gitleaks" detect \
    --source "$repo_root" \
    --redact --verbose
}

verify_dockerignore() {
  "${repo_root}/scripts/verify-dockerignore.sh"
}
```
</div>
<div class="small-code">
<div class="source-label">source: .github/workflows/security.yml</div>

```yaml
steps:
  - name: Scan repository secrets
    run: ./.tools/gitleaks detect --source . --redact --verbose
  - name: Verify Docker build contexts
    run: ./scripts/verify-dockerignore.sh
  - name: Lint Dockerfiles
    run: ./scripts/verify-dockerfiles.sh
```
</div>
</div>

<!--
pre-push hook은 개발자 장비에서 먼저 실행되는 빠른 차단선입니다.
GitHub Actions의 security workflow도 같은 성격의 검사를 한 번 더 실행합니다.
여기서는 비밀값, Docker build context, Dockerfile lint를 봅니다.
-->

---
layout: default
---

<div class="badge"><span class="num">12-2</span><span class="label">Image</span></div>

# image gate는 push 직전에 한 번 더 봅니다

<div class="split">
<div class="small-code">
<div class="source-label">source: scripts/security-image-scan.sh</div>

```bash
docker build --pull -f "$dockerfile" -t "$image_ref" "$context"

run_trivy "$image_ref"
"${repo_root}/scripts/scan-docker-history.sh" "$image_ref"
```
</div>
<div class="small-code">
<div class="source-label">source: scripts/scan-docker-history.sh</div>

```bash
secret_pattern='token|password|secret|AWS_ACCESS_KEY|AWS_SECRET_ACCESS_KEY|PRIVATE KEY'

if docker history --no-trunc "$image_ref" | grep -Eiq "$secret_pattern"; then
  echo "Potential secret-like text found in docker history" >&2
  exit 1
fi
```
</div>
</div>

<!--
이미지를 만들고 나면 source만 봐서는 놓치는 흔적이 생길 수 있습니다.
그래서 release image gate에서는 Trivy로 취약점과 secret, misconfig를 보고, docker history에 token이나 private key 같은 문자열이 남았는지도 확인합니다.
이 검사가 끝난 뒤에야 ECR push로 넘어갑니다.
-->

---
layout: default
---

<div class="badge"><span class="num">13</span><span class="label">릴리스</span></div>

# 릴리스는 kubectl apply가 아니라 Git 변경입니다

<div class="diagram-slide">
  <img :src="'/ci-cd-release-flow.png'" alt="CI/CD release flow diagram" />
  <div class="diagram-notes">
    <div class="point"><strong>입구</strong><span>`v*` Git tag가 릴리스 이미지 버전이 됩니다.</span></div>
    <div class="point"><strong>Actions</strong><span>이미지를 만들고, 스캔하고, Private ECR에 push합니다.</span></div>
    <div class="point"><strong>Argo CD</strong><span>release branch의 manifest 변경을 보고 클러스터를 맞춥니다.</span></div>
  </div>
</div>

<!--
릴리스에서 중요한 결정은 GitHub Actions가 클러스터에 직접 `kubectl apply`하지 않는다는 점입니다.
Actions는 이미지를 만들고 검증한 뒤 ECR에 올리고, release 브랜치의 Kustomize image tag만 바꿉니다.
실제 반영은 Argo CD가 Git 변경을 보고 수행합니다.
-->

---
layout: default
---

<div class="badge"><span class="num">13-1</span><span class="label">Workflow</span></div>

# release workflow는 세 단계로 읽으면 됩니다

<div class="split">
<div class="small-code">
<div class="source-label">source: .github/workflows/release.yml</div>

```yaml
on:
  push:
    tags:
      - 'v*'

jobs:
  source-security:
  build-images:
  update-manifests:
```
</div>
<div class="small-code">
<div class="source-label">source: .github/workflows/release.yml</div>

```yaml
env:
  AWS_REGION: ap-northeast-2
  IMAGE_TAG: ${{ github.ref_name }}
  KUSTOMIZE_DIR: k8s/overlays/aws
  MANIFEST_BRANCH: release
```
</div>
</div>

<!--
workflow는 세 단계로 읽으면 됩니다.
먼저 source-security가 source gate를 통과시키고, build-images가 서비스별 이미지를 만들고 스캔합니다.
마지막 update-manifests가 release 브랜치의 Kubernetes manifest를 바꿉니다.
Git tag가 이미지 tag가 되기 때문에 어떤 코드가 어떤 이미지로 나갔는지도 추적하기 쉽습니다.
-->

---
layout: default
---

<div class="badge"><span class="num">13-2</span><span class="label">Manifest</span></div>

# Argo CD가 보는 것은 이 overlay입니다

<div class="split">
<div class="small-code">
<div class="source-label">source: k8s/overlays/aws/kustomization.yaml</div>

```yaml
images:
  - name: zexpand/patient-service
    newName: 000000000000.dkr.ecr.ap-northeast-2.amazonaws.com/cloudnative-study/patient-service
    newTag: release-placeholder
```
</div>
<div class="small-code">
<div class="source-label">source: infra/cluster/gitops/argocd/applications/app.yaml</div>

```yaml
source:
  repoURL: https://github.com/asdqwce/cloudnative_study.git
  targetRevision: release
  path: k8s/overlays/aws
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```
</div>
</div>

<!--
Argo CD가 보는 것은 ECR 자체가 아니라 Git에 있는 manifest입니다.
release workflow가 `newTag`를 Git tag 값으로 바꾸면 Argo CD가 변경을 감지합니다.
그리고 Kubernetes가 새 Pod를 띄울 때 worker node가 Private ECR에서 이미지를 pull합니다.
-->
