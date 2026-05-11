# Generate random IP address space for VNet
resource "random_integer" "vnet_octet" {
  min = 10
  max = 254
}

# Virtual Network for AKS cluster
resource "azurerm_virtual_network" "default" {
  name                = "${random_pet.prefix.id}-vnet"
  address_space       = ["${random_integer.vnet_octet.result}.0.0.0/16"]
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  tags = {
    environment = "Demo"
  }
}

# Subnet for AKS cluster nodes
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["${random_integer.vnet_octet.result}.1.0.0/24"]

  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}
