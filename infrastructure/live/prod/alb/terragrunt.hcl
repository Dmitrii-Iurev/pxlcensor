include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//alb"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment       = "prod"
  region            = "us-east-1"
  vpc_id            = dependency.network.outputs.vpc_id
  public_subnet_ids = dependency.network.outputs.public_subnet_ids
  services          = ["frontend", "api", "media"]
  
  # Gebruik een certificaat dat gekoppeld is aan je prod-domein
  ssl_cert_arn      = "arn:aws:acm:us-east-1:905418273841:certificate/56d353bd-36c8-43d8-9916-cb3aabdbbf85"
}