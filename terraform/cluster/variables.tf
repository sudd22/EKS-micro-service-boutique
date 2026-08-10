variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "node_count" {
  type        = number
  description = "node count per env - 0 = fully parked, 1 = dev, 2 = prod multi-AZ"
}

variable "deploy_nat_gateway" {
  type        = bool
  description = " Toggle NAT Gateway for FinOps parking"
}

variable "domain_name" {
  type = string
}

variable "api_origin_domain" {
  type    = string
  default = "ALB DNS name"
}
