terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

# Secrets ophalen uit Secrets Manager
data "aws_secretsmanager_secret_version" "db" {
  secret_id = var.db_secret_arn
}

# RDS PostgreSQL instance
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.environment}-postgres"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["username"]
  password          = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot = true
  publicly_accessible = false
}

# Security Group voor database
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Allow access from internal services only"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # private netwerk
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Genereert een unieke suffix voor de secret naam
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# Database Secret Container
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "pxl-${var.environment}-db-creds-${random_id.secret_suffix.hex}"
  recovery_window_in_days = 0 # Handig voor lab: direct verwijderen bij destroy
}

# Database Secret Waarde
resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "postgres"
    password = var.db_password
    host     = var.db_endpoint
  })
}

# Media Signing Secret Container
resource "aws_secretsmanager_secret" "media_secret" {
  name                    = "pxl-${var.environment}-media-key-${random_id.secret_suffix.hex}"
  recovery_window_in_days = 0
}

# Media Signing Secret Waarde
resource "aws_secretsmanager_secret_version" "media_val" {
  secret_id     = aws_secretsmanager_secret.media_secret.id
  secret_string = var.media_signing_key
}