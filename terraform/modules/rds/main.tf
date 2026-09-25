resource "aws_db_subnet_group" "main" {
  name       = "microservice-rds-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name   = "microservice-rds-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "random_password" "master" {
  length  = 16
  special = false
}

resource "aws_db_instance" "main" {
  identifier        = "microservice-rds-${var.environment}"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.environment == "prod" ? "db.t4g.small" : "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "microservice"
  username = "postgres"
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  multi_az            = false
}
