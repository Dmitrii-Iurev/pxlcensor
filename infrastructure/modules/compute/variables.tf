variable "environment" { type = string }
variable "region" { type = string }
variable "services" { type = list(string) }
variable "autoscale" { type = bool }
variable "base_url" { type = string }
variable "media_secret_arn" { type = string }
variable "db_secret_arn" { type = string }
