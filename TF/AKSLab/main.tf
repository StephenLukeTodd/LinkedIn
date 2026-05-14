# =============================================================================
# Azure Kubernetes Service (AKS) with Key Vault Integration
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  # Uses current Azure CLI credentials
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Get current Azure subscription and tenant info
data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

# =============================================================================
# Core Resources
# =============================================================================

resource "random_pet" "prefix" {
  length = 2
}

resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.location
}

# =============================================================================
# Azure AD Service Principal Creation
# =============================================================================

# Create Azure AD application
resource "azuread_application" "aks_sp" {
  display_name = "${random_pet.prefix.id}-aks-sp"
  owners       = [data.azuread_client_config.current.object_id]
}

# Create service principal
resource "azuread_service_principal" "aks_sp" {
  client_id = azuread_application.aks_sp.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Create service principal password
resource "azuread_service_principal_password" "aks_sp" {
  service_principal_id = azuread_service_principal.aks_sp.object_id
}

# =============================================================================
# Outputs for Service Principal Credentials
# =============================================================================

output "service_principal_app_id" {
  description = "Service Principal Application ID"
  value       = azuread_service_principal.aks_sp.client_id
  sensitive   = true
}

output "service_principal_password" {
  description = "Service Principal Password"
  value       = azuread_service_principal_password.aks_sp.value
  sensitive   = true
}

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.default.name
}

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

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.default.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.default.login_server
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.default.id
}
