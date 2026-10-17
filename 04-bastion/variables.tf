variable "subscription_id" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    environment = "prod"
    project     = "landing-zone-students"
    managed_by  = "terraform"
  }
}
