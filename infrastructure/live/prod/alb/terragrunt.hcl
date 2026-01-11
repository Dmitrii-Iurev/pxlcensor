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
  ssl_cert_arn      = "arn:aws:acm:us-east-1:522279443716:certificate/6fafef34-dddb-4c78-9e87-7c7cb5591d86"
}