resource "azurerm_storage_account" "default" {
  name                     = "${random_pet.prefix.id}sa"
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Network Security - Disable Public Access
  public_network_access_enabled = false
  allow_nested_items_to_be_public = false
  
  # Data Protection - HTTPS & TLS
  min_tls_version     = "TLS1_2"
  https_traffic_only_enabled = true
  
  # Authentication - Disable Shared Key Access
  shared_access_key_enabled = false
  
  # Default Network Action to Deny
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = {
    environment = "Demo"
    security    = "high"
  }
}
