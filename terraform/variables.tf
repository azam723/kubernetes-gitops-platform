variable "aws_region" {
  description = "AWS region for the project"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the ECR publishing role"
  type        = string
  default     = "azam723/kubernetes-gitops-platform"
}

variable "github_owner_id" {
  description = "GitHub owner ID used by immutable OIDC subject claims"
  type        = string
  default     = "263730056"
}

variable "github_repository_id" {
  description = "GitHub repository ID used by immutable OIDC subject claims"
  type        = string
  default     = "1371817216"
}
