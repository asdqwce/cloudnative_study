# AWS GitOps Post-Merge Checklist

AWS GitOps 구성이 main에 merge된 뒤에는 `release` 브랜치와 GitHub repository variables를 한 번 준비해야 한다. 이 작업은 AWS 배포 환경 기준 Terraform state를 대상으로 실행한다.

## 1. Release Branch 준비

먼저 main 기준으로 `release` 브랜치를 만든다. 이미 원격 `release` 브랜치가 있다면 새로 만들지 말고 최신 main 변경을 반영하는 방식으로 갱신한다.

```bash
git fetch origin
git switch main
git pull --ff-only
git switch -c release
git push -u origin release
```

## 2. 공유 SSH Key 준비

배포 인스턴스는 팀이 공유해서 접근하므로 같은 SSH key pair를 사용한다. private key는 Git에 올리지 말고 1Password, Bitwarden, AWS Secrets Manager 같은 secret store로만 공유한다.

팀원은 공유받은 key를 다음 경로에 둔다.

```bash
~/.ssh/k8s-key
~/.ssh/k8s-key.pub
```

로컬 권한은 다음처럼 맞춘다.

```bash
chmod 600 ~/.ssh/k8s-key
chmod 644 ~/.ssh/k8s-key.pub
```

Terraform은 public key만 AWS key pair로 등록한다. `terraform/terraform.tfvars`에는 기본값을 그대로 쓰거나 다음 값을 명시한다.

```hcl
k8s_public_key_path = "~/.ssh/k8s-key.pub"
```

private key는 Ansible/SSH 접속에만 사용한다. 팀원이 빠지거나 key 유출이 의심되면 새 key pair를 만들고 인스턴스 접근 키를 교체한다.

## 3. Terraform Apply

AWS 리소스는 Terraform으로 생성한다. 로컬 profile을 쓸 때는 `terraform/terraform.tfvars`의 `aws_profile`을 배포 계정 profile에 맞춘다. access key 방식이 필요하면 `aws_profile = ""`로 두고 `aws_access_key`, `aws_secret_key`를 채운다.

```bash
make -C terraform apply
```

## 4. GitHub Variables 설정

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

## 5. Argo CD Bootstrap

GitHub variables까지 준비한 뒤 Argo CD bootstrap을 실행한다.

```bash
make aws-bootstrap
```

## 6. Release Workflow 실행

여기까지 끝나면 `v*` Git tag push 또는 manual `workflow_dispatch`로 release workflow를 실행한다. workflow는 이미지를 ECR에 push하고, `release` 브랜치의 `k8s/overlays/aws/kustomization.yaml` image 값을 갱신한다. Argo CD는 `release` 브랜치 변경을 감지해서 `medical-platform` namespace에 sync한다.
