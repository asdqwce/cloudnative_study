# GitHub Actions AWS credentials 설정 이슈

## 상황

Release workflow에서 이미지 빌드 후 ECR로 push하기 전에 다음 단계가 실패했다.

```text
Run aws-actions/configure-aws-credentials@v4
Error: Credentials could not be loaded, please check your action inputs: Could not load credentials from any providers
```

## 원인

workflow는 GitHub Actions OIDC로 AWS IAM Role을 assume하도록 구성되어 있다.

```yaml
role-to-assume: ${{ vars.AWS_RELEASE_ROLE_ARN }}
aws-region: ${{ env.AWS_REGION }}
```

하지만 GitHub repository variable `AWS_RELEASE_ROLE_ARN`이 설정되어 있지 않으면 `role-to-assume` 값이 비게 된다. 이 경우 `aws-actions/configure-aws-credentials`는 assume role을 수행하지 못하고 기본 AWS credential provider chain을 찾다가 실패한다.

이 문제는 Docker build나 ECR 권한 문제가 아니라, GitHub Actions가 AWS role ARN을 전달받지 못한 설정 문제다.

## 해결

Terraform apply 후 출력되는 `github_actions_release_role_arn` 값을 GitHub repository variable로 등록한다.

```bash
terraform -chdir=terraform output -raw github_actions_release_role_arn
```

출력된 값을 그대로 사용해 다음 명령을 실행한다.

```bash
gh variable set AWS_RELEASE_ROLE_ARN \
  --repo <owner>/<repo> \
  --body "$(terraform -chdir=terraform output -raw github_actions_release_role_arn)"
```

GitHub UI로 설정할 수도 있다.

```text
Repository Settings
-> Secrets and variables
-> Actions
-> Variables
-> New repository variable
```

등록할 값은 다음과 같다.

```text
Name: AWS_RELEASE_ROLE_ARN
Value: Terraform output github_actions_release_role_arn
```

## 확인

등록 후 GitHub repository variable이 보이는지 확인한다.

```bash
gh variable list --repo <owner>/<repo>
```

이후 release tag를 새로 push하거나 Release workflow를 다시 실행한다.

```bash
git tag <new-release-tag>
git push origin <new-release-tag>
```
