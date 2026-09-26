resource "aws_sqs_queue" "dlq" {
  name = "microservice-order-dlq-${var.environment}"
}

resource "aws_sqs_queue" "main" {
  name = "microservice-order-${var.environment}"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}
