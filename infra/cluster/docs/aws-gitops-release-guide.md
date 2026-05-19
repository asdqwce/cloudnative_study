# AWS GitOps Release Guide

이 문서는 AWS EC2 기반 Kubernetes 클러스터에 Argo CD를 설치하고, GitHub Actions와 Private ECR을 통해 릴리즈 브랜치 배포를 구성하기 위한 판단용 가이드라인이다.

로컬 AWS profile은 운영 배포의 필수 요소가 아니라 디버깅이나 수동 확인을 위한 보조 수단으로 둔다. 실제 릴리즈 경로의 핵심 인증은 GitHub Actions가 AWS IAM Role을 assume하고, ECR에 이미지를 push하는 방식으로 잡는다.

브랜치, Git tag, image tag, 단일 클러스터 환경 분리 전략은 `infra/cluster/docs/release-environment-strategy.md`를 기준으로 한다. 이 문서는 그 전략을 AWS GitOps 파이프라인으로 구현할 때 필요한 구성 요소를 다룬다.

ECR과 EC2 Kubernetes 클러스터는 같은 `ap-northeast-2` 리전에 둔다. 같은 리전을 쓰면 image pull 경로가 단순해지고, 리전 간 데이터 전송과 인증 혼동을 줄일 수 있다. 이 실습에서는 ECR Public이 아니라 계정 소유 Private ECR repository를 사용한다.

## 권장 구성

1. GitHub Actions가 AWS IAM Role을 assume한다.
2. GitHub Actions가 서비스별 Docker image를 build한다.
3. GitHub Actions가 ECR에 image를 push한다.
4. GitHub Actions가 대상 환경에 따라 `k8s/overlays/aws/dev/kustomization.yaml` 또는 `k8s/overlays/aws/prod/kustomization.yaml`의 image tag를 갱신해서 Git에 commit/push한다.
5. EC2 Kubernetes 위 Argo CD가 Git 변경을 감지한다.
6. Argo CD가 `release/dev -> k8s/overlays/aws/dev -> medical-platform-dev` 또는 `release/prod -> k8s/overlays/aws/prod -> medical-platform-prod`를 sync한다.
7. Kubernetes worker node가 Private ECR에서 image를 pull한다.

중요한 점은 Argo CD가 ECR 이미지를 직접 가져오는 주체가 아니라는 것이다. 실제 image pull은 Kubernetes node의 kubelet/containerd가 수행한다. 따라서 EC2 worker node에는 ECR pull 권한이 있는 IAM role이 필요하고, self-managed Kubernetes에서는 kubelet image credential provider 설정까지 별도로 준비해야 한다.

## Push 전 보안 게이트

보안 게이트는 막아야 하는 노출 위치에 따라 두 층으로 나눈다.

1. public repo 노출 방지
   - 목적: GitHub에 push되기 전에 source 안의 secret, 위험한 Docker build context, Dockerfile 문제를 막는다.
   - 로컬 pre-push hook과 GitHub Push Protection을 함께 사용한다.
   - Actions의 secret scan은 GitHub push 이후에 실행되므로 public repo 노출을 사전에 막는 장치로만 보기에는 늦다.

2. public registry 노출 방지
   - 목적: ECR 같은 registry에 image가 올라가기 전에 image layer와 history에 남은 secret-like 값을 막는다.
   - 현재 release workflow의 Trivy image scan과 Docker history scan이 담당한다.

### 로컬 pre-push 게이트

로컬 개발자는 sh 기반 Git hook을 설치해서 `git push` 직전에 source security gate를 실행한다. Windows는 Git for Windows가 제공하는 Git Bash 기준으로 지원하고, macOS/Linux는 기본 shell 환경에서 실행한다. hook wrapper는 `scripts/security/pre-push.sh`를 호출한다.

처음 한 번만 다음 명령을 실행한다.

```bash
make install
```

`make install`은 `scripts/security/bootstrap.sh`로 repo-local 보안 도구를 준비하고, `scripts/security/install-git-hooks.sh`로 Git hook을 설치한다. PowerShell 7이나 Python은 필요하지 않다.

hook 설치 스크립트는 다음 Git 설정을 repo-local로 적용한다.

```bash
git config core.hooksPath .githooks
```

보안 도구는 시스템 전역 설치보다 repo-local `.tools/`를 우선한다. `gitleaks`와 `hadolint`가 `.tools/`에 없으면 `scripts/security/bootstrap.sh`가 OS/architecture에 맞는 고정 버전을 다운로드하고 checksum을 검증한 뒤 재사용한다.

로컬 pre-push에서 실행하는 검사는 다음과 같다.

- repository secret scan: `gitleaks detect --source <repo> --redact --verbose`
- build context 검증: root Java 서비스는 repo root context, dashboard는 `dashboard/` context로 보고 각 context의 `.dockerignore` 필수 패턴을 검사한다.
- Dockerfile lint: repo 안의 모든 `Dockerfile`을 repo-local `hadolint`로 검사한다.

GitHub Push Protection은 별도 repository 설정이 필요하다. 로컬 pre-push hook은 개발자 장비의 빠른 차단선이고, GitHub Push Protection은 GitHub 원격에 도달하는 push를 한 번 더 막는 차단선이다.

### GitHub Actions 게이트

ECR image push 전에는 GitHub Actions에서 보안 차단 게이트를 먼저 통과해야 한다. 이 단계는 완전한 보장을 의미하지 않고, repo에 들어온 비밀값이나 Docker build 과정에서 남을 수 있는 위험을 push 이후 CI에서 다시 확인하는 역할을 한다.

PR과 일반 push에서는 `.github/workflows/security.yml`이 빠른 source 검증을 담당한다.

- repository secret scan: `.env`, `terraform.tfvars`, private key, token류가 repo에 들어오면 실패시킨다.
- Dockerfile lint: 현재 repo의 모든 `Dockerfile`을 `hadolint`로 검사한다.
- build context 검증: 각 Docker build context의 `.dockerignore`에 최소 제외 항목이 있는지 확인한다.

Git tag 기반 릴리즈에서는 `.github/workflows/release.yml`이 같은 source 검증을 먼저 실행한 뒤 image build로 넘어간다. image tag는 Git tag와 같은 값이다. image build 후에는 ECR login과 `docker push` 전에 다음 검사를 추가로 실행한다.

- Trivy image scan: `vuln`, `secret`, `misconfig` scanner로 HIGH/CRITICAL 위험을 차단한다.
- Docker history scan: `token`, `password`, `secret`, `AWS_ACCESS_KEY`, `AWS_SECRET_ACCESS_KEY`, `PRIVATE KEY` 같은 문자열이 layer history에 남으면 실패시킨다.

public image push 시에는 자동화만 믿지 말고 build arg, ENV, 임시 인증 파일, kubeconfig, Terraform 변수 파일이 build context에 들어가지 않는지 별도로 확인한다. Kong/Python 서비스가 main에 합쳐지면 release matrix와 `.dockerignore` 검증 대상에 해당 서비스 context를 추가한다.

## CI 쪽 AWS 인증

GitHub Actions에는 AWS access key를 저장하기보다 OIDC를 쓰는 편이 좋다.

필요한 AWS 리소스는 다음과 같다.

- GitHub OIDC Provider
- GitHub Actions용 IAM Role
- 특정 repository의 `release/dev`, `release/prod`, `v*` Git tag ref만 assume할 수 있는 role trust policy
- GitHub Actions role에 부여할 ECR push 권한
- EC2 node IAM Role에 부여할 ECR pull 권한

릴리즈 workflow는 Git tag push를 기준으로 이미지를 만들고, 기본적으로 `release/dev` manifest를 갱신한다. `release/prod`는 검증된 Git tag를 승격할 때 같은 image tag를 바라보도록 별도 승인 흐름에서 갱신한다.

```yaml
permissions:
  contents: write
  id-token: write

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<account-id>:role/github-actions-cloudnative-release
          aws-region: ap-northeast-2

      - uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push images
        run: |
          IMAGE_TAG=${GITHUB_REF_NAME}
          docker build -t <account-id>.dkr.ecr.ap-northeast-2.amazonaws.com/cloudnative-study/patient-service:$IMAGE_TAG ./services/patient-service
          docker push <account-id>.dkr.ecr.ap-northeast-2.amazonaws.com/cloudnative-study/patient-service:$IMAGE_TAG

      - name: Update kustomize image tags
        run: |
          cd k8s/overlays/aws/dev
          kustomize edit set image zexpand/patient-service=<account-id>.dkr.ecr.ap-northeast-2.amazonaws.com/cloudnative-study/patient-service:$IMAGE_TAG

      - name: Commit manifest change
        run: |
          git config user.name github-actions
          git config user.email github-actions@github.com
          git add k8s/overlays/aws/dev/kustomization.yaml
          git commit -m "deploy: update release images"
          git push
```

실제 workflow는 배포 대상 서비스 전체에 대해 build, push, image tag 갱신을 반복해야 한다.

현재 구현은 `auth-service`, `patient-service`, `appointment-service`, `prescription-service`, `notification-service`, `dashboard`를 서비스별 Private ECR repository로 다룬다. repository 이름은 `cloudnative-study/<service>` 형식을 유지한다.

## Worker Node의 ECR Pull 인증

이 클러스터는 EKS가 아니라 EC2 self-managed Kubernetes다. EKS worker처럼 기본 통합이 자동으로 처리된다고 가정하지 않는다.

EC2 worker instance profile에는 최소한 다음 ECR pull 권한이 필요하다.

- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:BatchGetImage`
- `ecr:GetDownloadUrlForLayer`

다만 instance profile만 붙였다고 kubelet/containerd가 Private ECR 인증을 자동으로 해결한다고 단정하면 안 된다. kubelet이 registry별 credential provider exec plugin을 호출하도록 각 worker node에 다음 설정을 추가하는 방향을 기준으로 둔다.

- `ecr-credential-provider` binary를 모든 worker node의 고정 경로에 설치한다.
- kubelet에 `--image-credential-provider-config`와 `--image-credential-provider-bin-dir`를 지정한다.
- `CredentialProviderConfig`의 `matchImages`에 `*.dkr.ecr.*.amazonaws.com` 패턴을 둔다.
- credential cache duration은 ECR token 수명에 맞춰 12시간 이내로 둔다.

`imagePullSecrets`는 ECR token이 12시간 후 만료되므로 장기 운영 방식으로 쓰지 않는다. 장애 대응이나 credential provider 도입 전 임시 검증에는 사용할 수 있지만, Git에 token이나 Docker config를 남기지 않는다.

현재 GitOps bootstrap은 Argo CD와 Application 등록까지 담당한다. worker node의 ECR credential provider 설치는 별도 클러스터 hardening 작업으로 남아 있으므로, Argo CD sync 완료 판단 전에는 worker에서 Private ECR image pull smoke를 먼저 통과시켜야 한다. 이 전제가 충족되지 않으면 Argo CD sync는 성공하더라도 Pod는 `ImagePullBackOff`가 될 수 있다.

## Argo CD 배포 방식

GitOps 원칙을 살리려면 GitHub Actions가 `kubectl apply`를 직접 실행하는 방식보다, Git manifest만 바꾸고 Argo CD가 pull/sync하도록 두는 방식이 좋다.

선택지는 두 가지다.

1. 완전 GitOps 방식
   - Actions는 ECR push와 manifest commit까지만 수행한다.
   - Argo CD는 auto sync로 배포한다.
   - 단순하고 처음 구성하기에 좋다.

2. GitOps + 즉시 sync 방식
   - Actions가 manifest commit 후 Argo CD API나 CLI로 `argocd app sync`를 호출한다.
   - 배포 타이밍을 더 즉시 제어할 수 있다.
   - GitHub Actions에 Argo CD token과 endpoint secret이 필요하다.

초기 구성에서는 완전 GitOps 방식을 우선한다. 릴리즈 브랜치 push 후 sync 완료까지 GitHub Actions에서 확인하고 싶어지면, 그때 즉시 sync 방식을 추가한다.

초기 Application은 환경별 앱 overlay만 바라보게 둔다. `deps`까지 한 Application에 묶으면 DB/Kafka 같은 상태ful 의존성과 앱 이미지 릴리즈가 같은 sync 주기로 움직이기 때문에, 먼저 앱 release 경로를 분리한다. 의존성 배포 자동화가 필요해지면 `aws-dev-deps`, `aws-prod-deps` Application을 별도로 추가한다.

또 하나의 decision point는 Argo CD가 추적할 릴리즈 브랜치다. GitHub Actions OIDC role은 `release/**` 전체를 허용할 수 있지만, Argo CD `targetRevision`은 하나의 구체적인 브랜치를 보는 편이 운영상 명확하다. 실습 기준은 `release/dev`, `release/prod`처럼 환경별 브랜치를 두고, 각 Argo CD Application의 `targetRevision`과 workflow 운용 브랜치를 함께 맞춘다.

### Feature branch smoke test

AWS Argo CD bootstrap을 feature 브랜치에서 먼저 확인할 때는 dev Application만 임시로 현재 feature 브랜치를 바라보게 둘 수 있다. 이 브랜치에서는 `infra/cluster/gitops/argocd/applications/app-dev.yaml`의 `targetRevision`을 `feature/aws-gitops-release-foundation`으로 둔다.

이 설정은 smoke test용 결정이다. 운영 promotion 흐름으로 넘기기 전에는 dev Application의 `targetRevision`을 `release/dev`로 되돌리고, prod Application은 계속 `release/prod`와 manual sync를 유지한다.

클러스터 bootstrap은 root `Makefile`의 AWS wrapper로 실행한다.

AWS bootstrap은 기본적으로 Terraform output에서 EC2 public IP를 읽어 Ansible inventory를 생성한다. Terraform workspace가 선택한 상태 파일에서 `master_public_ip`, `worker_public_ips`를 읽고, `control_plane`, `workers`, `kube_control_plane`, `kube_workers`, `k8s_cluster` 그룹을 담은 `.tools/ansible/aws.ini`를 만든다.

이 방식이면 `terraform apply` 뒤에 public IP를 `dev.ini`에 다시 적지 않아도 된다. 고정 IP inventory는 public IP가 바뀔 때마다 수동 갱신해야 하므로 기본 흐름에서는 생성된 `.tools/ansible/aws.ini`를 사용한다. `infra/cluster/provision/ansible/inventories/aws/dev.ini`는 필요할 때 `AWS_INVENTORY=...`로 지정하는 예시/비상용 fallback으로만 둔다.

```bash
make aws-ansible-syntax-check
make aws-servers-bootstrap
make aws-cluster-bootstrap
make aws-helm-bootstrap
make aws-argocd-bootstrap
```

전체 순서를 한 번에 실행하려면 `make aws-bootstrap`을 사용한다. 이 target은 Terraform output으로 inventory를 먼저 만든 뒤 bootstrap playbook을 순서대로 실행한다. 목표 흐름은 `make terraform apply && make aws-bootstrap`이다. Terraform `apply`와 원격 Ansible 실행은 실제 AWS 리소스와 EC2 서버에 영향을 주므로, dry-run이나 syntax check로 명령을 먼저 확인한 뒤 명시적으로 실행한다.

## Repository 변경 후보

- `terraform/`: ECR repositories, GitHub OIDC IAM role, EC2 node IAM role을 추가한다.
- `infra/cluster/provision/ansible/playbooks/bootstrap-argocd.yml`: Helm 기반 Argo CD 설치와 `infra/cluster/gitops/argocd` apply를 담당한다.
- `infra/cluster/gitops/argocd/projects/medical-platform.yaml`: dev/prod namespace destination만 허용하는 AppProject를 둔다.
- `infra/cluster/gitops/argocd/applications/app-dev.yaml`: `release/dev`, `k8s/overlays/aws/dev`, `medical-platform-dev`를 바라보고 자동 sync한다.
- `infra/cluster/gitops/argocd/applications/app-prod.yaml`: `release/prod`, `k8s/overlays/aws/prod`, `medical-platform-prod`를 바라보고 초기에는 수동 sync로 둔다.
- `k8s/overlays/aws/dev/kustomization.yaml`: dev용 ECR image URI와 release tag placeholder를 사용한다.
- `k8s/overlays/aws/prod/kustomization.yaml`: prod용 ECR image URI와 release tag placeholder를 사용한다.
- `.github/workflows/release.yml`: `v*` Git tag용 ECR build/push와 대상 release branch manifest update workflow를 둔다.

## 배포 이해

GitOps에서는 배포 행위가 직접 클러스터에 명령을 실행하는 방식에서 Git에 선언된 원하는 상태를 바꾸는 방식으로 바뀐다.

```text
새 이미지 build
→ ECR에 push
→ Git의 Kubernetes manifest에서 image tag 변경
→ Git push
→ Argo CD가 Git 변경 감지
→ 클러스터 상태를 Git 상태와 맞춤
→ 새 이미지로 rollout
```

예를 들어 `k8s/overlays/aws/dev/kustomization.yaml` 또는 `k8s/overlays/aws/prod/kustomization.yaml`에서 image tag가 바뀌면 Argo CD가 변경을 감지하고 해당 Deployment의 Pod를 새 이미지로 교체한다.

```yaml
images:
  - name: zexpand/patient-service
    newName: 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/cloudnative-study/patient-service
    newTag: v1.2.3
```

정리하면 앱 배포는 `이미지 태그 변경 -> Git push -> Argo CD sync`로 이루어진다. Terraform과 Ansible은 클러스터와 배포 시스템을 만들고, GitHub Actions는 이미지를 만들고 manifest를 갱신하며, Argo CD는 Git manifest를 Kubernetes에 반영한다.
