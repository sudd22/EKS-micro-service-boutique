terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.0"
        }
    }
}

provider "aws" {
    region = var.region
    default_tags {
        tags = {
            Project     = "b2b-eks-platform"
            Environment = "multi-tenant-cluster"
            ManagedBy   = "terraform"   
        }
    }
}