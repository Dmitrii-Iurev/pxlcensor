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
  environment            = "test"
  # Voor TEST: alles op 1 houden conform de opdracht
  api_min_capacity       = 1
  api_max_capacity       = 1
  processor_min_capacity = 1
  processor_max_capacity = 1
  
  region             = "us-east-1"
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  
  # Data van andere modules
  # Check even of je output 'db_instance_endpoint' of 'db_endpoint' heet in de database module
  db_endpoint = dependency.database.outputs.db_endpoint
  target_group_arns  = dependency.alb.outputs.target_group_arns
  base_url           = "https://${dependency.alb.outputs.alb_dns_name}"
  alb_sg_id          = dependency.alb.outputs.alb_sg_id
  
  # Applicatie instellingen
  services           = ["frontend", "api", "media"]
  autoscale          = false # Dit zorgt dat de autoscaling target resource niet wordt aangemaakt
  
  # Secrets
  db_secret_arn      = dependency.database.outputs.db_secret_arn
  media_secret_arn   = dependency.database.outputs.media_secret_arn
}