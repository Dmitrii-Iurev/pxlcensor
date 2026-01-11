variable "environment"        { type = string }
variable "region"             { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }

# Deze waarden gebruiken we om de secrets te vullen
variable "db_password" {
  type      = string
  sensitive = true
}

variable "media_signing_key" {
  type      = string
  sensitive = true
}