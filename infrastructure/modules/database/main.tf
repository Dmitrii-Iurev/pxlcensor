terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

# 1. DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
}

# 2. De Database Instance
resource "aws_db_instance" "postgres" {
  identifier           = "${var.environment}-postgres"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  # GEBRUIK HIER DIRECT DE VARIABELEN (Niet de data source!)
  username             = "postgres"
  password             = var.db_password 
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}

# 3. Security Group
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Allow access from internal services only"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Unieke ID voor Secret Namen
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# 5. Database Secret in Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  # Gebruik de suffix om "name already exists" fouten te voorkomen
  name                    = "pxl-${var.environment}-db-creds-${random_id.secret_suffix.hex}"
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "postgres"
    password = var.db_password
    host     = aws_db_instance.postgres.address # GEFIXT: Verwijst nu naar 'postgres'
    port     = 5432
  })
}

# 6. Media Secret
resource "aws_secretsmanager_secret" "media_secret" {
  name                    = "pxl-${var.environment}-media-key-${random_id.secret_suffix.hex}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "media_val" {
  secret_id     = aws_secretsmanager_secret.media_secret.id
  secret_string = var.media_signing_key
}