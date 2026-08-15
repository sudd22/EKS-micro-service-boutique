module "vpc" {
  source             = "../modules/vpc"
  deploy_nat_gateway = var.deploy_nat_gateway
}

module "eks" {
  source             = "../modules/eks"
  node_count         = var.node_count
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "karpenter" {
  source           = "../modules/karpenter"
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
}

module "rds_dev" {
  source             = "../modules/rds"
  environment        = "dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}
module "rds_prod" {
  source             = "../modules/rds"
  environment        = "prod"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}
module "sqs_dev" {
  source      = "../modules/sqs"
  environment = "dev"
}
module "sqs_prod" {
  source      = "../modules/sqs"
  environment = "prod"
}


module "monitoring_storage" {
  source       = "../modules/monitoring_storage"
  cluster_name = module.eks.cluster_name
}
module "pod_identity" {
  source              = "../modules/pod_identity"
  cluster_name        = module.eks.cluster_name
  sns_aiops_topic_arn = data.terraform_remote_state.persistent.outputs.sns_aiops_topic_arn

  db_secret_arns = data.terraform_remote_state.persistent.outputs.db_secret_arns

  sqs_queue_arns = {
    dev  = module.sqs_dev.queue_arn
    prod = module.sqs_prod.queue_arn
  }

  sqs_dlq_arns = {
    dev  = module.sqs_dev.dlq_arn
    prod = module.sqs_prod.dlq_arn
  }
}

module "waf" {
  source = "../modules/waf"
}
module "cloudfront_frontend" {
  source                                 = "../modules/cloudfront_frontend"
  domain_name                            = var.domain_name
  api_origin_domain                      = var.api_origin_domain
  storefront_bucket_regional_domain_name = "${data.terraform_remote_state.persistent.outputs.storefront_bucket}.s3.${var.region}.amazonaws.com"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}
