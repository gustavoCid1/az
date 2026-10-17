output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = {
    app       = azurerm_subnet.app.id
    db        = azurerm_subnet.db.id
    vm        = azurerm_subnet.vm.id
    endpoints = azurerm_subnet.endpoints.id
    bastion   = azurerm_subnet.bastion.id
  }
}

output "dns_zone_ids" {
  value = {
    postgres = azurerm_private_dns_zone.postgres.id
    blob     = azurerm_private_dns_zone.blob.id
  }
}
