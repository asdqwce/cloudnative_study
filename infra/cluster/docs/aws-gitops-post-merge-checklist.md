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

## 2. Terraform Apply

AWS 리소스는 Terraform으로 생성한다. 로컬 profile을 쓸 때는 `terraform/terraform.tfvars`의 `aws_profile`을 배포 계정 profile에 맞춘다. access key 방식이 필요하면 `aws_profile = ""`로 두고 `aws_access_key`, `aws_secret_key`를 채운다.

```bash
make -C terraform apply
```

## 3. GitHub Variables 설정

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

## 4. Argo CD Bootstrap

GitHub variables까지 준비한 뒤 Argo CD bootstrap을 실행한다.

```bash
make aws-bootstrap
```

## 5. Release Workflow 실행

여기까지 끝나면 `v*` Git tag push 또는 manual `workflow_dispatch`로 release workflow를 실행한다. workflow는 이미지를 ECR에 push하고, `release` 브랜치의 `k8s/overlays/aws/kustomization.yaml` image 값을 갱신한다. Argo CD는 `release` 브랜치 변경을 감지해서 `medical-platform` namespace에 sync한다.
