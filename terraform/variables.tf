variable "aws_region" {
  description = "AWS region for the EC2 Kubernetes cluster and ECR repositories."
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_profile" {
  description = "AWS CLI profile name. When set, Terraform uses this profile instead of direct access keys."
  type        = string
  default     = "cloudnative-study"
}

variable "aws_access_key" {
  description = "AWS Access Key. Used only when aws_profile is empty."
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS Secret Key. Used only when aws_profile is empty."
  type        = string
  sensitive   = true
  default     = ""
}

variable "k8s_public_key_path" {
  description = "Path to the shared SSH public key registered as the EC2 key pair. Defaults to ~/.ssh/k8s-key.pub for macOS, Linux, WSL, and Git Bash."
  type        = string
  default     = "~/.ssh/k8s-key.pub"
}

variable "k8s_public_key" {
  description = "Inline SSH public key registered as the EC2 key pair when k8s_public_key_path is set to empty."
  type        = string
  default     = ""
}

variable "ecr_repository_prefix" {
  description = "Base prefix for service ECR repositories. Terraform appends the current workspace, for example cloudnative-study-lab/patient-service."
  type        = string
  default     = "cloudnative-study"
}

variable "ecr_service_repositories" {
  description = "Service repository names to create in ECR. Keep app-specific future services as explicit placeholders until they exist in the repo."
  type        = set(string)
  default = [
    "auth-service",
    "patient-service",
    "appointment-service",
    "prescription-service",
    "notification-service",
    "dashboard",
  ]
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability for service repositories."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "ecr_force_delete" {
  description = "Whether Terraform can delete non-empty ECR repositories in this learning environment."
  type        = bool
  default     = false
}

variable "github_repository_owner" {
  description = "GitHub repository owner allowed to assume the release role."
  type        = string
  default     = "asdqwce"
}

variable "github_repository_name" {
  description = "GitHub repository name allowed to assume the release role."
  type        = string
  default     = "cloudnative_study"
}

variable "github_actions_release_branches" {
  description = "Release state branches allowed to assume the GitHub Actions release role."
  type        = set(string)
  default     = ["release"]
}

variable "github_actions_tag_pattern" {
  description = "Git tag pattern allowed to assume the GitHub Actions release role for image publishing."
  type        = string
  default     = "v*"
}

variable "github_actions_role_name" {
  description = "IAM role name assumed by the release workflow through GitHub Actions OIDC."
  type        = string
  default     = "github-actions-cloudnative-release"
}

variable "github_oidc_thumbprints" {
  description = "TLS thumbprints for the GitHub Actions OIDC provider."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
