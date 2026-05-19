variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "public_key_path" {
  description = "SSH 공개키 경로 (각자 본인 경로로 설정)"
  type        = string
  default     = "~/.ssh/k8s-key.pub"
}
