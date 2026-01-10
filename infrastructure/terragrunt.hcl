# infrastructure/terragrunt.hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "pxlcensor-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pxlcensor-locks"
    encrypt        = true
  }
}

terraform {
  extra_arguments "env_vars" {
    commands = ["apply", "plan"]
    env_vars = {
      AWS_PROFILE = "default"
    }
  }
}
