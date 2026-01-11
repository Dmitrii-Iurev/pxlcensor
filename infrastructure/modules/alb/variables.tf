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

# In modules/alb/variables.tf
variable "ssl_cert_arn" {
  description = "Niet meer nodig als we het cert zelf maken"
  type        = string
  default     = null # Dit zorgt ervoor dat hij niet meer verplicht is
}

variable "services" {
  type        = list(string)
  default     = ["api", "media", "frontend"]
  description = "Lijst van services die via de ALB bereikbaar moeten zijn"
}