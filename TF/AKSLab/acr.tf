# Azure Container Registry for storing container images
resource "azurerm_container_registry" "default" {
  name                = "${replace(random_pet.prefix.id, "-", "")}acr"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "Standard"
  admin_enabled       = true

  # Network Configuration - Private access with AKS subnet whitelisted
  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = "${random_integer.vnet_octet.result}.1.0/24" # AKS subnet
    }
  }

  # Data Protection Configuration - Standard SKU doesn't support retention policy
  # retention_policy {
  #   days    = 14
  #   enabled = true
  # }

  # Trust Policy for signed images - Standard SKU doesn't support trust policy
  # trust_policy {
  #   enabled = true
  # }

  tags = {
    environment = "Demo"
    purpose     = "container-registry"
  }
}

# Grant ACR pull/push permissions to AKS service principal
resource "azurerm_role_assignment" "acr_contributor" {
  scope                = azurerm_container_registry.default.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.aks_sp.object_id
}

# Additional role for pull permissions
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.default.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.aks_sp.object_id
}
