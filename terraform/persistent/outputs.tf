output "ecr_repository_urls" {
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
  description = "Map of service name to ECR repository URL"
}

output "db_secret_arns" {
  value       = { for k, s in aws_secretsmanager_secret.db : k => s.arn }
  description = "Map of env-service key to Secrets Manager secret ARN"
}

output "postgres_exporter_secret_arns" {
  value       = { for k, s in aws_secretsmanager_secret.postgres_exporter : k => s.arn }
  description = "Map of env to postgres exporter secret ARN"
}

output "sns_aiops_topic_arn" {
  value       = aws_sns_topic.aiops_alerts.arn
  description = "ARN of the aiops SNS topic"
}

output "runbooks_bucket" {
  value       = aws_s3_bucket.runbooks.bucket
  description = "S3 bucket for AIOps runbooks"
}
output "storefront_bucket" {
  value       = aws_s3_bucket.storefront.bucket
  description = "S3 bucket for static storefront"
}
