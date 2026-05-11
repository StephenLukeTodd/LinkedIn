# =============================================================================
# Azure Kubernetes Service (AKS) with Key Vault Integration
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
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

