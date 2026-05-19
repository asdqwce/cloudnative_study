locals {
  ecr_workspace_repository_prefix = "${var.ecr_repository_prefix}-${terraform.workspace}"

  # 서비스 이름을 ECR repository 이름으로 변환
  ecr_repository_names = {
    for service in var.ecr_service_repositories :
    service => "${local.ecr_workspace_repository_prefix}/${service}"
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
    Name      = each.value
    Service   = each.key
    Workspace = terraform.workspace
  }
}

# 태그가 없는 오래된 image layer만 정리한다.
resource "aws_ecr_lifecycle_policy" "service" {
  for_each = aws_ecr_repository.service

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days."
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
