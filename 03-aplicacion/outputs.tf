output "app_url" {
  value = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "app_principal_id" {
  value = azurerm_linux_web_app.this.identity[0].principal_id
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}
