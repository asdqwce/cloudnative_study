provider "aws" {
  region = var.aws_region

  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" && var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_profile == "" && var.aws_secret_key != "" ? var.aws_secret_key : null
}

# 현재 AWS 계정 정보 조회
data "aws_caller_identity" "current" {}

# 키페어 등록
resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key-${terraform.workspace}"
  public_key = var.k8s_public_key_path != "" ? file(pathexpand(var.k8s_public_key_path)) : var.k8s_public_key
}

# 보안그룹
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg-${terraform.workspace}"
  description = "Security group for K8s cluster (${terraform.workspace})"

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
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # 아웃바운드 모두 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "k8s-sg-${terraform.workspace}"
    Workspace = terraform.workspace
  }
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
    Name      = "k8s-master-${terraform.workspace}"
    Role      = "master"
    Workspace = terraform.workspace
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
  depends_on             = [aws_instance.master]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name      = "k8s-worker-${terraform.workspace}-${count.index + 1}"
    Role      = "worker"
    Workspace = terraform.workspace
  }
}

# 출력
output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_public_ips" {
  value = aws_instance.worker[*].public_ip
}

output "workspace" {
  value = terraform.workspace
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
