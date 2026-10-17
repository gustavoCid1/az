variable "subscription_id" {
  type = string
}

variable "pg_admin_login" {
  description = "Usuario administrador local de PostgreSQL"
  type        = string
  default     = "pgadmin"
}

variable "pg_admin_password" {
  description = "Contraseña del administrador (mín. 8 caracteres, con mayúsculas, minúsculas y números)"
  type        = string
  sensitive   = true
}

variable "tags" {
  type = map(string)
  default = {
    environment = "prod"
    project     = "landing-zone-students"
    managed_by  = "terraform"
  }
}
