include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//compute"
}

dependency "network" {
  config_path = "../network"
}

dependency "database" {
  config_path = "../database"
}

dependency "alb" {
  config_path = "../alb"
}

inputs = {
  environment        = "test"
  region             = "us-east-1"
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  
  # Data van andere modules
  db_endpoint        = dependency.database.outputs.db_endpoint
  target_group_arns  = dependency.alb.outputs.target_group_arns
  base_url           = "https://${dependency.alb.outputs.alb_dns_name}"

  # VOEG DEZE REGEL TOE:
  alb_sg_id          = dependency.alb.outputs.alb_security_group_id
  
  # Applicatie instellingen
  services           = ["frontend", "api", "media", "processor"]
  autoscale          = false # EIS: Test draait op 1 instance
  
  # Secrets
  db_secret_arn      = "arn:aws:secretsmanager:us-east-1:905418273841:secret:test/db/credentials-aF0mMb"
  media_secret_arn   = "arn:aws:secretsmanager:us-east-1:905418273841:secret:test/media/signing_secret-QQ26IZ"
}