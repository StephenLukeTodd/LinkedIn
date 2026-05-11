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
  description = "Key Vault Name storing credentials"
  value       = azurerm_key_vault.default.name
}

