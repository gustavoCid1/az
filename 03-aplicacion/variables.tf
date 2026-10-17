variable "subscription_id" {
  type = string
}

variable "ssh_public_key" {
  description = "Contenido de tu llave pública SSH (ssh-ed25519 AAAA... o ssh-rsa AAAA...)"
  type        = string
}

variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "prod"
    project     = "landing-zone-students"
    managed_by  = "terraform"
  }
}
