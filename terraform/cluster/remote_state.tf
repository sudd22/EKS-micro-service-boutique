data "terraform_remote_state" "persistent" {
  backend = "s3"
  config = {
    bucket = "microservice-eks-platform-tfstate-boutique"
    key    = "persistent/terraform.tfstate"
    region = "eu-west-2"
  }
}
