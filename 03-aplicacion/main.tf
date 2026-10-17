data "azurerm_client_config" "current" {}

data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

data "terraform_remote_state" "datos" {
  backend = "local"
  config = {
    path = "../02-datos/terraform.tfstate"
  }
}

locals {
  net  = data.terraform_remote_state.network.outputs
  data = data.terraform_remote_state.datos.outputs
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# ---------------- App Service Linux B1 + VNet Integration ----------------
resource "azurerm_service_plan" "this" {
  name                = "asp-lzprod"
  resource_group_name = local.net.resource_group_name
  location            = local.net.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-lzprod-${random_string.suffix.result}"
  resource_group_name = local.net.resource_group_name
  location            = local.net.location
  service_plan_id     = azurerm_service_plan.this.id

  https_only                = true
  virtual_network_subnet_id = local.net.subnet_ids["app"] # VNet Integration (snet-app)

  identity {
    type = "SystemAssigned" # MI
  }

  site_config {
    vnet_route_all_enabled = true
    minimum_tls_version    = "1.2"

    application_stack {
      python_version = "3.12"
    }
  }

  app_settings = {
    PGHOST        = local.data.pg_server_fqdn
    PGDATABASE    = "postgres"
    PGUSER        = "app-lzprod-${random_string.suffix.result}" # autenticación con token MI
    BLOB_ENDPOINT = local.data.blob_endpoint
  }

  tags = var.tags
}

# ---------------- VM Linux B2ats_v2 (worker) ----------------
resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-worker"
  location            = local.net.location
  resource_group_name = local.net.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.net.subnet_ids["vm"]
    private_ip_address_allocation = "Dynamic"
    # Sin IP pública: el acceso es solo por Bastion
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "vm-worker"
  resource_group_name = local.net.resource_group_name
  location            = local.net.location
  size                = "Standard_B2ats_v2"

  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  identity {
    type = "SystemAssigned" # MI
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

# ---------------- RBAC: Managed Identity -> Blob ----------------
resource "azurerm_role_assignment" "app_blob" {
  scope                = local.data.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "vm_blob" {
  scope                = local.data.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

# ---------------- Entra ID admin en PostgreSQL para cada MI ----------------
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "app" {
  server_name         = local.data.pg_server_name
  resource_group_name = local.net.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = azurerm_linux_web_app.this.identity[0].principal_id
  principal_name      = azurerm_linux_web_app.this.name
  principal_type      = "ServicePrincipal"
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "vm" {
  server_name         = local.data.pg_server_name
  resource_group_name = local.net.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = azurerm_linux_virtual_machine.this.identity[0].principal_id
  principal_name      = azurerm_linux_virtual_machine.this.name
  principal_type      = "ServicePrincipal"

  # Evita dos operaciones simultáneas sobre el mismo servidor
  depends_on = [azurerm_postgresql_flexible_server_active_directory_administrator.app]
}
