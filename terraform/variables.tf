variable "project_name" {
  description = "리소스 이름과 태그에 사용할 프로젝트 이름"
  type        = string
  default     = "medikong"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

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

variable "ami_id" {
  description = "EC2 노드에 사용할 AMI ID"
  type        = string
  default     = "ami-0f5ddb19e2fbe4cc4"
}

variable "master_instance_type" {
  description = "Kubernetes control-plane EC2 인스턴스 타입"
  type        = string
  default     = "r6g.large"
}

variable "worker_instance_type" {
  description = "Kubernetes worker EC2 인스턴스 타입"
  type        = string
  default     = "r6g.medium"
}

variable "worker_count" {
  description = "Kubernetes worker 노드 개수"
  type        = number
  default     = 2
}

variable "volume_type" {
  description = "EC2 root volume 타입"
  type        = string
  default     = "gp3"
}

variable "master_volume_size" {
  description = "control-plane root volume 크기(GB)"
  type        = number
  default     = 30
}

variable "worker_volume_size" {
  description = "worker root volume 크기(GB)"
  type        = number
  default     = 20
}

variable "allowed_ssh_cidrs" {
  description = "SSH 접근을 허용할 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_k8s_api_cidrs" {
  description = "Kubernetes API Server 접근을 허용할 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecr_repositories" {
  description = "프로젝트 서비스별 ECR repository 이름 목록"
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

variable "ecr_force_delete" {
  description = "repository 안에 이미지가 있어도 Terraform destroy 시 ECR repository를 삭제할지 여부"
  type        = bool
  default     = true
}

variable "nlb_internal" {
  description = "NLB를 내부용으로 만들지 여부. false면 인터넷-facing NLB입니다."
  type        = bool
  default     = false
}

variable "nlb_listener_port" {
  description = "NLB가 외부에서 받을 포트"
  type        = number
  default     = 80
}

variable "nlb_target_port" {
  description = "NLB가 worker EC2로 전달할 포트"
  type        = number
  default     = 80
}

variable "nlb_health_check_protocol" {
  description = "NLB target group health check 프로토콜"
  type        = string
  default     = "TCP"
}
