########################
#     Resource map     #
########################
# - key vault
# - key vault secret

########################
#       Data           #
########################

# Credentials for the current Azure connection/session
data "azurerm_client_config" "current" {}

# Main resource group
data "azurerm_resource_group" "main" {
  name = var.existingResourceGroupName
}

########################
#       Resource       #
########################

# Key Vault for storing credentials for the Virtual Machine
resource "azurerm_key_vault" "WindowsVmKeyVault" {
  name                       = "hovhanneshovkeyvault"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  enabled_for_deployment     = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
    ]

    secret_permissions = [
      "list",
      "set",
      "get",
      "delete",
      "purge",
      "recover"
    ]

    storage_permissions = [
      "get",
    ]
  }
}

# Adding secret for the Key Vault
resource "azurerm_key_vault_secret" "adminuserPassword" {
  name         = "adminuserPassword"
  value        = var.adminuserPassword
  key_vault_id = azurerm_key_vault.WindowsVmKeyVault.id
}