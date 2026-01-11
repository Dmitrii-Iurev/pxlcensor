variable "environment" {
  type        = string
  description = "De omgeving (test/prod)"
}

variable "region" {
  type        = string
  description = "AWS regio"
}

variable "vpc_id" {
  type        = string
  description = "De VPC ID waar de ALB en Target Groups in komen"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Lijst van publieke subnets voor de ALB"
}

variable "ssl_cert_arn" {
  type        = string
  description = "De handmatige ARN van het certificaat"
}

variable "services" {
  type        = list(string)
  default     = ["api", "media", "frontend"]
  description = "Lijst van services die via de ALB bereikbaar moeten zijn"
}