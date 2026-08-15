terraform {
  backend "s3" {
    bucket         = "microservice-eks-platform-tfstate-boutique"
    key            = "persistent/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "microservice-eks-platform-tflocks"
    encrypt        = true
  }
}


