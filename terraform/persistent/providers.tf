terraform {
  required_version = ">=1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }

  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "microservice-eks-platform"
      Environment = "persistent"
      ManagedBy   = "terraform"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-2"
}





