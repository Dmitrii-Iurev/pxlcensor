include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/compute"
}

inputs = {
  environment    = "prod"
  region         = "us-east-1"
  services       = ["api","processor","frontend","media"]
  autoscale      = true
  base_url       = "https://pxlcensor.example.com"
  media_secret_arn = "arn:aws:ssm:us-east-1:1234567890:parameter/prod/MEDIA_SIGNING_SECRET"
  db_secret_arn    = "arn:aws:ssm:us-east-1:1234567890:parameter/prod/POSTGRES_PASSWORD"
}
