variable "subscription_id" {
  description = "ID de la suscripción Azure for Students"
  type        = string
}

variable "location" {
  description = "Región. Verifica qué regiones permite la política de tu suscripción Azure for Students."
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  type    = string
  default = "rg-lz-prod"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "prod"
    project     = "landing-zone-students"
    managed_by  = "terraform"
  }
}
