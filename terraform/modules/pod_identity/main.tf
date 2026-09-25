resource "aws_iam_role" "order_sqs" {
  name = "microservice-order-sqs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
    Service = "pods.eks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "order_sqs" {
  name = "order-sqs-publish"
  role = aws_iam_role.order_sqs.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sqs:SendMessage"
      Effect   = "Allow"
      Resource = [var.sqs_queue_arns["dev"], var.sqs_queue_arns["prod"]]
    }]
  })
}

resource "aws_eks_pod_identity_association" "order_sqs" {
  for_each        = toset(["dev", "prod"])
  cluster_name    = var.cluster_name
  namespace       = each.key
  service_account = "order-sa"
  role_arn        = aws_iam_role.order_sqs.arn
}

resource "aws_iam_role" "notification_sqs" {
  name = "microservice-notification-sqs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "notification_sqs" {
  name = "notification-sqs-consume"
  role = aws_iam_role.notification_sqs.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Effect   = "Allow"
      Resource = [var.sqs_queue_arns["dev"], var.sqs_queue_arns["prod"], var.sqs_dlq_arns["dev"], var.sqs_dlq_arns["prod"]]
    }]
  })
}

resource "aws_eks_pod_identity_association" "notification_sqs" {
  for_each        = toset(["dev", "prod"])
  cluster_name    = var.cluster_name
  namespace       = each.key
  service_account = "notification-sa"
  role_arn        = aws_iam_role.notification_sqs.arn
}

resource "aws_iam_role" "alertmanager" {
  name = "microservice-alertmanager-sns"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "alertmanager" {
  name = "alertmanager-sns"
  role = aws_iam_role.alertmanager.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sns:Publish"
      Effect   = "Allow"
      Resource = var.sns_aiops_topic_arn
    }]
  })
}

resource "aws_eks_pod_identity_association" "alertmanager" {
  cluster_name    = var.cluster_name
  namespace       = "monitoring"
  service_account = "alertmanager"
  role_arn        = aws_iam_role.alertmanager.arn
}

locals {
  services    = ["auth", "product", "order", "payment", "notification"]
  envs        = ["dev", "prod"]
  service_env = { for pair in setproduct(local.envs, local.services) : "${pair[0]}-${pair[1]}" => { "env" = pair[0], "svc" = pair[1] } }
}


resource "aws_iam_role" "db_secret" {
  for_each = local.service_env
  name     = "microservice-db-secret-${each.key}"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "pods.eks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "db_secret" {
  for_each = local.service_env
  name     = "read-db-secret-${each.key}"
  role     = aws_iam_role.db_secret[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "secretsmanager:GetSecretValue"
      Effect   = "Allow"
      Resource = var.db_secret_arns[each.key]
    }]
  })
}

resource "aws_eks_pod_identity_association" "db_secret" {
  for_each        = local.service_env
  cluster_name    = var.cluster_name
  namespace       = each.value.env
  service_account = "${each.value.svc}-sa"
  role_arn        = aws_iam_role.db_secret[each.key].arn
}

resource "aws_iam_role" "auth_throttle" {
  name = "microservice-auth-throttle-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "auth_throttle" {
  name = "auth-throttle-scan"
  role = aws_iam_role.auth_throttle.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "dynamodb:Scan"
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_eks_pod_identity_association" "auth_throttle" {
  for_each        = toset(["dev", "prod"])
  cluster_name    = var.cluster_name
  namespace       = each.key
  service_account = "auth-sa"
  role_arn        = aws_iam_role.auth_throttle.arn
}

resource "aws_iam_role" "otel_xray" {
  name = "microservice-otel-xray-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "otel_xray" {
  role       = aws_iam_role.otel_xray.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_eks_pod_identity_association" "otel_xray" {
  cluster_name    = var.cluster_name
  namespace       = "monitoring"
  service_account = "otel-collector"
  role_arn        = aws_iam_role.otel_xray.arn
}
