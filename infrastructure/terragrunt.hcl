# infrastructure/live/terragrunt.hcl

remote_state {
  backend = "s3"
  config = {
    bucket         = "pxlcensor-terraform-state23"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pxlcensor-locks"
    encrypt        = true
  }
}

# DIT VOEGT DE ONTBREKENDE PROVIDER CONFIG TOE AAN ELKE MODULE
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}

# VERWIJDER HET OUDE "extra_arguments" BLOK VOLLEDIG