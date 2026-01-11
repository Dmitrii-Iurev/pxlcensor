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
  
    db_password       = "PXL_Secret_2026!" 
    media_signing_key = "Media_Secret_Key_123!"
}