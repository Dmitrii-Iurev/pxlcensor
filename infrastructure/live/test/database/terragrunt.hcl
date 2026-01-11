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
  environment        = "test"
  region             = "us-east-1"
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  # De ARN van je secret in AWS Secrets Manager
  db_secret_arn      = "arn:aws:secretsmanager:us-east-1:905418273841:secret:test/db/credentials-aF0mMb"
}