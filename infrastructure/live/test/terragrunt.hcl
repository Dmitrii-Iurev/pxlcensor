include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/compute"
}

inputs = {
  environment    = "test"
  region         = "us-east-1"
  services       = ["api","processor","frontend","media"]
  autoscale      = false
  base_url       = "https://test.example.com"
  media_secret_arn = "arn:aws:ssm:us-east-1:1234567890:parameter/test/MEDIA_SIGNING_SECRET"
  db_secret_arn    = "arn:aws:ssm:us-east-1:1234567890:parameter/test/POSTGRES_PASSWORD"
}
