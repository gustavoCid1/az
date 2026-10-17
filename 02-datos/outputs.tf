output "pg_server_name" {
  value = azurerm_postgresql_flexible_server.this.name
}

output "pg_server_fqdn" {
  value = azurerm_postgresql_flexible_server.this.fqdn
}

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}
