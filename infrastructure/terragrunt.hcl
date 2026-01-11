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

# DIT ZORGT VOOR DE EXPLICIT CONFIGURATIE (Lost Error 1 op)
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}

# VERWIJDER HET "extra_arguments" BLOK DAT JE EERDER HAD
# DAT BLOK ZOCHT NAAR AWS_PROFILE = "default" EN DAT VEROORZAAKT ERROR 2