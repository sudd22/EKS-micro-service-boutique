variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_master_password" {
  value     = random_password.master.result
  sensitive = true
}
