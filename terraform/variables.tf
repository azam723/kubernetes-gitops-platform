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
