locals {
  github_actions_release_role_name = "${var.github_actions_role_name}-${terraform.workspace}"
  worker_node_role_name            = "k8s-worker-node-${terraform.workspace}"

  # GitHub Actions OIDC assume role 허용 ref 조건
  github_actions_oidc_subjects = concat(
    [
      for branch in var.github_actions_release_branches :
      "repo:${var.github_repository_owner}/${var.github_repository_name}:ref:refs/heads/${branch}"
    ],
    [
      "repo:${var.github_repository_owner}/${var.github_repository_name}:ref:refs/tags/${var.github_actions_tag_pattern}"
    ]
  )
}

# GitHub Actions OIDC provider 등록
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints
}

# release 브랜치 GitHub Actions가 assume할 IAM Role
resource "aws_iam_role" "github_actions_release" {
  name = local.github_actions_release_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.github_actions_oidc_subjects
          }
        }
      }
    ]
  })

  tags = {
    Name      = local.github_actions_release_role_name
    Workspace = terraform.workspace
  }
}

# GitHub Actions의 ECR image push 권한
resource "aws_iam_policy" "github_actions_ecr_push" {
  name        = "${local.github_actions_release_role_name}-ecr-push"
  description = "Allow release workflows to push service images to ECR."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = [for repo in aws_ecr_repository.service : repo.arn]
      }
    ]
  })
}

# GitHub Actions Role에 ECR push 정책 연결
resource "aws_iam_role_policy_attachment" "github_actions_ecr_push" {
  role       = aws_iam_role.github_actions_release.name
  policy_arn = aws_iam_policy.github_actions_ecr_push.arn
}

# EC2 worker node가 사용할 IAM Role
resource "aws_iam_role" "worker_node" {
  name = local.worker_node_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = local.worker_node_role_name
    Workspace = terraform.workspace
  }
}

# EC2 worker node의 ECR image pull 권한
resource "aws_iam_policy" "worker_ecr_pull" {
  name        = "${local.worker_node_role_name}-ecr-pull"
  description = "Allow Kubernetes worker nodes to pull service images from ECR."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [for repo in aws_ecr_repository.service : repo.arn]
      }
    ]
  })
}

# Worker Role에 ECR pull 정책 연결
resource "aws_iam_role_policy_attachment" "worker_ecr_pull" {
  role       = aws_iam_role.worker_node.name
  policy_arn = aws_iam_policy.worker_ecr_pull.arn
}

# Worker EC2에 IAM Role을 붙이기 위한 instance profile
resource "aws_iam_instance_profile" "worker_node" {
  name = local.worker_node_role_name
  role = aws_iam_role.worker_node.name
}
