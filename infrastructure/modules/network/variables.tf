variable "environment" {
  type        = string
  description = "De omgeving (test of prod)"
}

variable "region" {
  type        = string
  description = "De AWS regio (bijv. us-east-1)"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "De IP-range voor de VPC"
}