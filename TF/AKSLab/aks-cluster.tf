resource "azurerm_kubernetes_cluster" "default" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"
  kubernetes_version  = "1.34"
  oidc_issuer_enabled = true

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2s_v3"
    os_disk_size_gb = 30
  }
  storage_profile {
    blob_driver_enabled = true # Required for Blob storage PVs
  }
  service_principal {
    client_id     = azuread_service_principal.aks_sp.client_id
    client_secret = azuread_service_principal_password.aks_sp.value
  }

  role_based_access_control_enabled = true

  tags = {
    environment = "Demo"
  }
}
