# Configure the Azure provider
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
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "random_pet" "prefix" {
  length = 2
}

resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.location
}

# Using existing service principal instead of creating new one
