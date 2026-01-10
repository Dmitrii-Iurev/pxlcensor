include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//database"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment        = "prod"
  region             = "us-east-1"
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  
  # Zorg dat je een unieke secret hebt voor productie!
  db_secret_arn      = "arn:aws:secretsmanager:us-east-1:123456789:secret:prod/db-pass"
}