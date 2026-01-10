variable "environment" { type = string }
variable "region" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "ssl_cert_arn" { type = string }
variable "services" { type = list(string) } # api, media, frontend
