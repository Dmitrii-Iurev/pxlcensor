# --- Algemene Instellingen ---
variable "environment" {
  type        = string
  description = "De omgeving waarin we deployen (test of prod)"
}

variable "region" {
  type        = string
  description = "De AWS regio"
}

# --- Netwerk Koppeling ---
variable "vpc_id" {
  type        = string
  description = "ID van de VPC waar de containers in komen"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Lijst van private subnets voor de Fargate taken"
}

# --- Applicatie Configureren ---
variable "services" {
  type        = list(string)
  default     = ["frontend", "api", "media", "processor"]
  description = "Lijst van de pxlcensor services die we als container draaien"
}

variable "base_url" {
  type        = string
  description = "De publieke base URL van de applicatie (gebruikt voor callback URLs)"
}

# --- Database Koppeling ---
variable "db_endpoint" {
  type        = string
  description = "Het adres van de RDS instance (host:poort)"
}

# --- Secrets (Eis: Geen hardcoded secrets) ---
variable "media_secret_arn" {
  type        = string
  description = "De ARN van de secret voor de MEDIA_SIGNING_SECRET in Secrets Manager of SSM"
}

variable "db_secret_arn" {
  type        = string
  description = "De ARN van de secret voor het POSTGRES_PASSWORD"
}

# --- Schaalbaarheid (Eis: Autoscaling conditional) ---
variable "autoscale" {
  type        = bool
  description = "Of autoscaling ingeschakeld moet worden (True voor PROD, False voor TEST)"
}

variable "api_min_capacity" {
  type    = number
  default = 1
}

variable "api_max_capacity" {
  type    = number
  default = 1 # Voor TEST blijft dit 1, voor PROD wordt dit 2
}

# --- Load Balancer Koppeling ---
variable "target_group_arns" {
  type        = map(string)
  description = "Een map van de Target Group ARNs komende van de ALB module (frontend, api, media)"
}

# --- Security Groups ---
variable "alb_sg_id" {
  type        = string
  description = "De Security Group ID van de ALB (om inkomend verkeer op de containers toe te staan)"
}