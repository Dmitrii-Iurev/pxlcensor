include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//compute"
}

dependency "network"  { config_path = "../network" }
dependency "database" { config_path = "../database" }
dependency "alb"      { config_path = "../alb" }

inputs = {
  environment        = "prod"
  autoscale          = true  # EIS: Schakel autoscaling in voor PROD
  
  # Capaciteit instellingen voor de Processor/API
  api_min_capacity   = 1
  api_max_capacity   = 2     # EIS: Maximaal 2 instances in PROD
  
  # Netwerk & Database (komen uit prod dependencies)
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  db_endpoint        = dependency.database.outputs.db_endpoint
  
  # Load Balancer
  target_group_arns  = dependency.alb.outputs.target_group_arns
  base_url           = "https://pxlcensor-prod.jouwdomein.be" # Je echte URL
  
  # Productie Secrets (Andere ARNs dan in TEST!)
  db_secret_arn      = "arn:aws:secretsmanager:region:905418273841:secret:prod/db-pass"
  media_secret_arn   = "arn:aws:secretsmanager:region:905418273841:secret:prod/media-key"
  
  services           = ["frontend", "api", "media", "processor"]
}