data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

locals {
  net = data.terraform_remote_state.network.outputs
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion"
  location            = local.net.location
  resource_group_name = local.net.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = "bas-lz-prod"
  location            = local.net.location
  resource_group_name = local.net.resource_group_name
  sku                 = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = local.net.subnet_ids["bastion"]
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
