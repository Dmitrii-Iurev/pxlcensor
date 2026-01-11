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
  
  # De ARN is nu gecorrigeerd (accolade verwijderd uit de string) en het blok wordt netjes gesloten
  ssl_cert_arn      = "arn:aws:acm:us-east-1:522279443716:certificate/2a349654-99ed-46ac-977d-5503a0153f30"
}