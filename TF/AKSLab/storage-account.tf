# =============================================================================
# Azure Storage Account for Blob Storage
# =============================================================================

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
    versioning_enabled = true
    change_feed_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = {
    environment = "Demo"
    security    = "high"
    purpose     = "blob-storage"
  }
}

# =============================================================================
# Blob Storage Containers
# =============================================================================

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

# =============================================================================
# Role-Based Access Control (RBAC)
# =============================================================================

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.default.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.aks_sp.object_id
}

# =============================================================================
# Storage Account Outputs
# =============================================================================

output "storage_account_name" {
  description = "Name of the secure blob storage account"
  value       = azurerm_storage_account.default.name
}

output "storage_account_id" {
  description = "ID of the secure blob storage account"
  value       = azurerm_storage_account.default.id
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.default.primary_blob_endpoint
}

output "storage_account_containers" {
  description = "List of created blob containers"
  value = [
    azurerm_storage_container.data.name,
    azurerm_storage_container.logs.name
  ]
}
