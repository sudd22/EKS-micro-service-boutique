variable "cluster_name" {
  type = string
}

variable "sns_aiops_topic_arn" {
  type = string
}

variable "db_secret_arns" {
  type = map(string)
}

variable "sqs_queue_arns" {
  type = map(string)
}

variable "sqs_dlq_arns" {
  type = map(string)
}
