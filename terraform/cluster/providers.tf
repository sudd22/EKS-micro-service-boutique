terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.3.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "microservice-eks-platform"
      Environment = "multi-tenant-cluster"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "microservice-eks-platform"
      Environment = "multi-tenant-cluster"
      ManagedBy   = "terraform"
    }
  }
}


provider "helm" {
  kubernetes = {
    host = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(
      module.eks.cluster_certificate_authority_data
    )

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", module.eks.cluster_name,
        "--region", var.region
      ]
    }
  }
}

provider "kubernetes" {
  host = module.eks.cluster_endpoint

  cluster_ca_certificate = base64decode(
    module.eks.cluster_certificate_authority_data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", module.eks.cluster_name,
      "--region", var.region
    ]
  }
}