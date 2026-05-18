provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 현재 AWS 계정 정보 조회
data "aws_caller_identity" "current" {}

locals {
  # 서비스 이름을 ECR repository 이름으로 변환
  ecr_repository_names = {
    for service in var.ecr_service_repositories :
    service => "${var.ecr_repository_prefix}/${service}"
  }

  # GitHub Actions OIDC assume role 허용 브랜치 조건
  github_actions_oidc_subject = "repo:${var.github_repository_owner}/${var.github_repository_name}:ref:refs/heads/${var.github_actions_branch_pattern}"
}

# 키페어 등록
resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = file("C:/.ssh/k8s-key.pub")
}

# 보안그룹
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for K8s cluster"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K8s API 서버
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort 범위
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 노드간 통신
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # 아웃바운드 모두 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-security-group"
  }
}

# 서비스별 ECR repository 생성
resource "aws_ecr_repository" "service" {
  for_each = local.ecr_repository_names

  name                 = each.value
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = each.value
    Service = each.key
  }
}

# GitHub Actions OIDC provider 등록
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints
}

# release 브랜치 GitHub Actions가 assume할 IAM Role
resource "aws_iam_role" "github_actions_release" {
  name = var.github_actions_role_name

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
            "token.actions.githubusercontent.com:sub" = local.github_actions_oidc_subject
          }
        }
      }
    ]
  })

  tags = {
    Name = var.github_actions_role_name
  }
}

# GitHub Actions의 ECR image push 권한
resource "aws_iam_policy" "github_actions_ecr_push" {
  name        = "${var.github_actions_role_name}-ecr-push"
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
  name = "k8s-worker-node"

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
    Name = "k8s-worker-node"
  }
}

# EC2 worker node의 ECR image pull 권한
resource "aws_iam_policy" "worker_ecr_pull" {
  name        = "k8s-worker-ecr-pull"
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
  name = "k8s-worker-node"
  role = aws_iam_role.worker_node.name
}

# 마스터 노드
resource "aws_instance" "master" {
  ami                    = "ami-0f5ddb19e2fbe4cc4" # Ubuntu 24.04 ARM64 서울 리전
  instance_type          = "r6g.large"
  key_name               = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-master"
    Role = "master"
  }
}

# 워커 노드 2개
resource "aws_instance" "worker" {
  count                  = 2
  ami                    = "ami-0f5ddb19e2fbe4cc4" # Ubuntu 24.04 ARM64 서울 리전
  instance_type          = "r6g.medium"
  key_name               = aws_key_pair.k8s_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.worker_node.name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  depends_on = [aws_instance.master]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}

# 출력
output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_public_ips" {
  value = aws_instance.worker[*].public_ip
}

# 서비스별 ECR repository URL 출력
output "ecr_repository_urls" {
  value = {
    for service, repo in aws_ecr_repository.service :
    service => repo.repository_url
  }
}

# GitHub Actions에서 사용할 release role ARN 출력
output "github_actions_release_role_arn" {
  value = aws_iam_role.github_actions_release.arn
}

# 현재 AWS 계정 ID 출력
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}
