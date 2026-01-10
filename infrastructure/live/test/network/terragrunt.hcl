include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//network"
}

inputs = {
  environment = "test"
  region      = "us-east-1"
  vpc_cidr    = "10.0.0.0/16"
}