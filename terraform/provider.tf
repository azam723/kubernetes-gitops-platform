provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "kubernetes-gitops-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
