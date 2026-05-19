# AWS GitOps Release Guide

이 문서는 AWS EC2 기반 Kubernetes 클러스터에 Argo CD를 설치하고, GitHub Actions와 Private ECR을 통해 단일 릴리즈 브랜치 배포를 구성하기 위한 가이드다.

로컬 AWS profile은 디버깅이나 수동 확인을 위한 보조 수단으로 둔다. 릴리즈 경로의 핵심 인증은 GitHub Actions가 AWS IAM Role을 assume하고, ECR에 이미지를 push하는 방식으로 잡는다.

ECR과 EC2 Kubernetes 클러스터는 같은 `ap-northeast-2` 리전에 둔다. 같은 리전을 쓰면 image pull 경로가 단순해지고, 리전 간 데이터 전송과 인증 혼동을 줄일 수 있다. 이 실습에서는 ECR Public이 아니라 계정 소유 Private ECR repository를 사용한다.

## 권장 구성

1. GitHub Actions가 AWS IAM Role을 assume한다.
2. GitHub Actions가 서비스별 Docker image를 build한다.
3. GitHub Actions가 ECR에 image를 push한다.
4. GitHub Actions가 `k8s/overlays/aws/kustomization.yaml`의 image tag를 갱신해서 `release` 브랜치에 commit/push한다.
5. EC2 Kubernetes 위 Argo CD가 Git 변경을 감지한다.
6. Argo CD가 `release -> k8s/overlays/aws -> medical-platform`을 sync한다.
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
   - release workflow의 Trivy image scan과 Docker history scan이 담당한다.

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

보안 도구는 시스템 전역 설치보다 repo-local `.tools/`를 우선한다. `make install` 또는 `make security-bootstrap`을 실행하면 `scripts/security/bootstrap.sh`가 OS/architecture에 맞는 고정 버전을 다운로드하고 checksum을 검증한 뒤 재사용한다.

로컬 pre-push에서 실행하는 검사는 다음과 같다. 단, `pre-push`는 push 시점에 보안 도구를 자동 설치하지 않는다. repo-local `.tools/`에 `gitleaks` 또는 `hadolint`가 준비되어 있으면 해당 검사를 실행하고, 없으면 안내 메시지만 출력한 뒤 스킵한다.

- repository secret scan: `gitleaks detect --source <repo> --redact --verbose`
- build context 검증: root Java 서비스는 repo root context, dashboard는 `dashboard/` context로 보고 각 context의 `.dockerignore` 필수 패턴을 검사한다.
- Dockerfile lint: repo 안의 모든 `Dockerfile`을 repo-local `hadolint`로 검사한다.

GitHub Push Protection은 별도 repository 설정이 필요하다. 로컬 pre-push hook은 개발자 장비의 빠른 차단선이고, GitHub Push Protection은 GitHub 원격에 도달하는 push를 한 번 더 막는 차단선이다.

### GitHub Actions 게이트

ECR image push 전에는 GitHub Actions에서 보안 차단 게이트를 먼저 통과해야 한다. 이 단계는 repo에 들어온 비밀값이나 Docker build 과정에서 남을 수 있는 위험을 push 이후 CI에서 다시 확인하는 역할을 한다.

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
- 특정 repository의 `release` 브랜치와 `v*` Git tag ref만 assume할 수 있는 role trust policy
- GitHub Actions role에 부여할 ECR push 권한
- EC2 node IAM Role에 부여할 ECR pull 권한

릴리즈 workflow는 Git tag push를 기준으로 이미지를 만들고, `release` 브랜치의 manifest를 갱신한다.

## Main Merge 후 작업

AWS GitOps 구성이 main에 merge된 뒤에는 `release` 브랜치와 GitHub repository variables를 한 번 준비해야 한다. 이 작업은 AWS 배포 환경 기준 Terraform state를 대상으로 실행한다.

먼저 main 기준으로 `release` 브랜치를 만든다. 이미 원격 `release` 브랜치가 있다면 새로 만들지 말고 최신 main 변경을 반영하는 방식으로 갱신한다.

```bash
git fetch origin
git switch main
git pull --ff-only
git switch -c release
git push -u origin release
```

AWS 리소스는 Terraform으로 생성한다. 로컬 profile을 쓸 때는 `terraform/terraform.tfvars`의 `aws_profile`을 배포 계정 profile에 맞춘다. access key 방식이 필요하면 `aws_profile = ""`로 두고 `aws_access_key`, `aws_secret_key`를 채운다.

```bash
make -C terraform apply
```

Terraform apply 후 GitHub Actions가 사용할 repository variables를 Terraform output에서 설정한다.

```bash
gh variable set AWS_RELEASE_ROLE_ARN \
  --body "$(terraform -chdir=terraform output -raw github_actions_release_role_arn)"

gh variable set ECR_REPOSITORY_PREFIX \
  --body "$(terraform -chdir=terraform output -raw ecr_repository_prefix)"
```

값은 다음 의미를 가진다.

- `AWS_RELEASE_ROLE_ARN`: GitHub Actions가 OIDC로 assume할 AWS IAM Role ARN
- `ECR_REPOSITORY_PREFIX`: release workflow가 ECR image URI를 만들 때 사용할 repository prefix

이후 Argo CD bootstrap을 실행한다.

```bash
make aws-bootstrap
```

여기까지 끝나면 `v*` Git tag push 또는 manual `workflow_dispatch`로 release workflow를 실행한다. workflow는 이미지를 ECR에 push하고, `release` 브랜치의 `k8s/overlays/aws/kustomization.yaml` image 값을 갱신한다. Argo CD는 `release` 브랜치 변경을 감지해서 `medical-platform` namespace에 sync한다.

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
          cd k8s/overlays/aws
          kustomize edit set image zexpand/patient-service=<account-id>.dkr.ecr.ap-northeast-2.amazonaws.com/cloudnative-study/patient-service:$IMAGE_TAG

      - name: Commit manifest change
        run: |
          git config user.name github-actions
          git config user.email github-actions@github.com
          git add k8s/overlays/aws/kustomization.yaml
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

AWS bootstrap은 로컬 registry를 끄고, 별도 AWS 전용 playbook으로 kubelet ECR credential provider를 켠다. 공용 `bootstrap-servers.yml`와 `bootstrap-cluster.yml`는 Vagrant/local kubeadm 흐름에서도 쓰이므로 ECR 설정을 넣지 않는다.

root `Makefile`은 사용자가 직접 실행할 `make aws-bootstrap`만 노출한다. 세부 bootstrap 단계는 `terraform/Makefile` 안에서 내부 target으로 관리하고, 공용 cluster bootstrap 뒤에 `bootstrap-aws-ecr-credential-provider.yml`을 실행한다. 이 AWS 전용 playbook은 worker node에 provider binary와 `CredentialProviderConfig`를 설치하고, `/etc/default/kubelet`의 `KUBELET_EXTRA_ARGS`에 다음 flag를 추가한다.

```text
--image-credential-provider-config=/etc/kubernetes/ecr-credential-provider.yaml
--image-credential-provider-bin-dir=/opt/kubelet-credential-providers
```

이 설정 뒤에도 실제 인증 경계는 worker node의 IAM Role이다. provider는 node IAM credential로 ECR authorization token을 얻어 kubelet/containerd image pull 경로에 전달할 뿐이고, GitHub Actions나 Argo CD가 직접 `kubectl apply`하거나 registry token을 Kubernetes Secret으로 주입하지 않는다.

## Argo CD 배포 방식

GitOps 원칙을 살리려면 GitHub Actions가 `kubectl apply`를 직접 실행하는 방식보다, Git manifest만 바꾸고 Argo CD가 pull/sync하도록 두는 방식이 좋다.

초기 구성에서는 완전 GitOps 방식을 우선한다. Actions는 ECR push와 manifest commit까지만 수행하고, Argo CD는 auto sync로 배포한다. 릴리즈 브랜치 push 후 sync 완료까지 GitHub Actions에서 확인하고 싶어지면, 그때 Argo CD API나 CLI 호출을 추가한다.

초기 Application은 앱 overlay만 바라보게 둔다. `deps`까지 한 Application에 묶으면 DB/Kafka 같은 상태ful 의존성과 앱 이미지 릴리즈가 같은 sync 주기로 움직이기 때문에, 먼저 앱 release 경로를 분리한다.

클러스터 bootstrap은 root `Makefile`의 AWS wrapper로 실행한다.

AWS bootstrap은 기본적으로 Terraform output에서 EC2 public IP를 읽어 Ansible inventory를 생성한다. Terraform workspace가 선택한 상태 파일에서 `master_public_ip`, `worker_public_ips`를 읽고, `control_plane`, `workers`, `kube_control_plane`, `kube_workers`, `k8s_cluster` 그룹을 담은 `.tools/ansible/aws.ini`를 만든다.

```bash
make aws-bootstrap
```

이 target은 root에서 노출되는 유일한 AWS bootstrap 진입점이다. 내부적으로는 Terraform output으로 inventory를 먼저 만든 뒤 서버, 클러스터, ECR credential provider, Helm, Argo CD bootstrap playbook을 순서대로 실행한다. 목표 흐름은 `make terraform apply && make aws-bootstrap`이다. Terraform `apply`와 원격 Ansible 실행은 실제 AWS 리소스와 EC2 서버에 영향을 주므로, dry-run이나 syntax check로 명령을 먼저 확인한 뒤 명시적으로 실행한다.

개발 중 세부 playbook syntax를 확인해야 할 때는 root 명령으로 노출하지 않고 Terraform 작업 디렉터리에서 내부 검증 target을 실행한다.

```bash
make -C terraform aws-ansible-syntax-check
```

## Repository 변경 후보

- `terraform/`: ECR repositories, GitHub OIDC IAM role, EC2 node IAM role을 추가한다.
- `infra/cluster/provision/ansible/playbooks/bootstrap-argocd.yml`: Helm 기반 Argo CD 설치와 `infra/cluster/gitops/argocd` apply를 담당한다.
- `infra/cluster/gitops/argocd/projects/medical-platform.yaml`: `medical-platform` namespace destination을 허용하는 AppProject를 둔다.
- `infra/cluster/gitops/argocd/applications/app.yaml`: `release`, `k8s/overlays/aws`, `medical-platform`을 바라보고 자동 sync한다.
- `k8s/overlays/aws/kustomization.yaml`: ECR image URI와 release tag placeholder를 사용한다.
- `.github/workflows/release.yml`: `v*` Git tag용 ECR build/push와 release branch manifest update workflow를 둔다.

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

예를 들어 `k8s/overlays/aws/kustomization.yaml`에서 image tag가 바뀌면 Argo CD가 변경을 감지하고 해당 Deployment의 Pod를 새 이미지로 교체한다.

```yaml
images:
  - name: zexpand/patient-service
    newName: 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/cloudnative-study/patient-service
    newTag: v1.2.3
```

정리하면 앱 배포는 `이미지 태그 변경 -> Git push -> Argo CD sync`로 이루어진다. Terraform과 Ansible은 클러스터와 배포 시스템을 만들고, GitHub Actions는 이미지를 만들고 manifest를 갱신하며, Argo CD는 Git manifest를 Kubernetes에 반영한다.
