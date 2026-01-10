include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules"
}

# Network
dependency "network" {
  config_path = "../network"
}

# Database
dependency "database" {
  config_path = "../database"
}

# ALB
dependency "alb" {
  config_path = "../alb"
}

inputs = {
  environment        = "prod"
  region             = "us-east-1"
  services           = ["api","processor","frontend","media"]
  autoscale          = true
  base_url           = "https://pxlcensor.example.com"
  media_secret_arn   = "arn:aws:ssm:us-east-1:1234567890:parameter/prod/MEDIA_SIGNING_SECRET"
  db_secret_arn      = "arn:aws:ssm:us-east-1:1234567890:parameter/prod/POSTGRES_PASSWORD"
  vpc_id             = dependency.network.outputs.vpc_id
  public_subnet_ids  = dependency.network.outputs.public_subnet_ids
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  ssl_cert_arn       = "arn:aws:acm:us-east-1:1234567890:certificate/prod-cert"
}
