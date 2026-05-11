resource "azurerm_storage_account" "default" {
  name                     = "${random_pet.prefix.id}sa"
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Network Security Configuration
  public_network_access_enabled     = false
  allow_nested_items_to_be_public   = false
  
  # Data Protection Configuration
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  
  # Authentication Configuration
  shared_access_key_enabled         = false
  
  # Network Rules Configuration
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  # Blob Service Configuration
  blob_properties {
    versioning_enabled = false
    change_feed_enabled = false
  }

  tags = {
    environment = "Demo"
    security    = "high"
    purpose     = "blob-storage"
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.default.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.default.name
  container_access_type = "private"
}

# Grant Storage Blob Data Contributor to Service Principal (AKS Cluster)
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.default.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.aks_sp.object_id
}

# Grant Storage Queue Data Contributor to Service Principal (for AKS logging)
resource "azurerm_role_assignment" "storage_queue_contributor" {
  scope                = azurerm_storage_account.default.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azuread_service_principal.aks_sp.object_id
}

# Grant Storage Account Contributor to Service Principal (for full access)
resource "azurerm_role_assignment" "storage_account_contributor" {
  scope                = azurerm_storage_account.default.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azuread_service_principal.aks_sp.object_id
}

