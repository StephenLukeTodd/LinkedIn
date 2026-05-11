
resource "azurerm_key_vault" "default" {
  name                        = "${random_pet.prefix.id}-kv"
  location                    = azurerm_resource_group.default.location
  resource_group_name         = azurerm_resource_group.default.name
  tenant_id                   = data.azuread_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = false

  access_policy {
    tenant_id = data.azuread_client_config.current.tenant_id
    object_id = data.azuread_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Purge"
    ]
  }

  access_policy {
    tenant_id = data.azuread_client_config.current.tenant_id
    object_id = azuread_service_principal.aks_sp.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover"
    ]
  }
}

# Store service principal credentials in Key Vault
resource "azurerm_key_vault_secret" "app_id" {
  name         = "aks-sp-app-id"
  value        = azuread_service_principal.aks_sp.client_id
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "app_password" {
  name         = "aks-sp-app-password"
  value        = azuread_service_principal_password.aks_sp.value
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "tenant_id" {
  name         = "aks-sp-tenant-id"
  value        = data.azuread_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.default.name
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "storage_account_endpoint" {
  name         = "storage-account-endpoint"
  value        = azurerm_storage_account.default.primary_blob_endpoint
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "acr_login_server" {
  name         = "acr-login-server"
  value        = azurerm_container_registry.default.login_server
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = azurerm_container_registry.default.admin_username
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.default.admin_password
  key_vault_id = azurerm_key_vault.default.id
}
