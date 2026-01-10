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
  environment       = "test"
  region            = "us-east-1"
  vpc_id            = dependency.network.outputs.vpc_id
  public_subnet_ids = dependency.network.outputs.public_subnet_ids
  services          = ["frontend", "api", "media"]
  # Gebruik hier de ARN van het certificaat dat je (handmatig of via ACM) hebt
  ssl_cert_arn      = "arn:aws:acm:us-east-1:123456789:certificate/uuid"
}