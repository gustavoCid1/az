data "azurerm_client_config" "current" {}

data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

locals {
  net = data.terraform_remote_state.network.outputs
}

# Sufijo para nombres globalmente únicos
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# ---------------- PostgreSQL Flexible Server (sin acceso público) ----------------
resource "azurerm_postgresql_flexible_server" "this" {
  name                = "psql-lzprod-${random_string.suffix.result}"
  resource_group_name = local.net.resource_group_name
  location            = local.net.location

  version                = "16"
  sku_name               = "B_Standard_B1ms" # Burstable B1ms
  storage_mb             = 32768
  backup_retention_days  = 7
  administrator_login    = var.pg_admin_login
  administrator_password = var.pg_admin_password

  public_network_access_enabled = false

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [zone]
  }
}

# ---------------- Storage Account (Blob, Standard LRS, sin acceso público) ----------------
resource "azurerm_storage_account" "this" {
  name                = "stlzprod${random_string.suffix.result}"
  resource_group_name = local.net.resource_group_name
  location            = local.net.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# ---------------- Private Endpoint PostgreSQL (10.0.2.4 en snet-db) ----------------
resource "azurerm_private_endpoint" "postgres" {
  name                = "pe-postgres"
  location            = local.net.location
  resource_group_name = local.net.resource_group_name
  subnet_id           = local.net.subnet_ids["db"]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-postgres"
    private_connection_resource_id = azurerm_postgresql_flexible_server.this.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "ipconfig-postgres"
    private_ip_address = "10.0.2.4"
    subresource_name   = "postgresqlServer"
    member_name        = "postgresqlServer"
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [local.net.dns_zone_ids["postgres"]]
  }
}

# ---------------- Private Endpoint Blob (10.0.4.4 en snet-endpoints) ----------------
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob"
  location            = local.net.location
  resource_group_name = local.net.resource_group_name
  subnet_id           = local.net.subnet_ids["endpoints"]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "ipconfig-blob"
    private_ip_address = "10.0.4.4"
    subresource_name   = "blob"
    member_name        = "blob"
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [local.net.dns_zone_ids["blob"]]
  }
}
