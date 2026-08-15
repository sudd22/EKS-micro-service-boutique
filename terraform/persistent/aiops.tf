resource "aws_s3_bucket" "runbooks" {
  bucket        = "microservice-platform-aiops-runbooks-boutique"
  force_destroy = true
}

resource "aws_sns_topic" "aiops_alerts" {
  name = "aiops-alerts"
}

resource "aws_dynamodb_table" "throttle_config" {
  name         = "ai-throtle-config"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "RuleName"

  attribute {
    name = "RuleName"
    type = "S"
  }
  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }
  tags = {
    layer = "aiops"
  }
}
