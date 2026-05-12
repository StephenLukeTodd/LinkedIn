# Public IP for Kubernetes LoadBalancer Service
resource "azurerm_public_ip" "video_player_lb" {
  name                = "video-player-lb-ip"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "video-player-${random_pet.prefix.id}"
  zones               = ["1", "2", "3"] # Zone-redundant for high availability
  
  tags = {
    environment = "Demo"
    purpose     = "Kubernetes LoadBalancer"
  }
}

# Public IP for Application Gateway (if needed for HTTPS)
resource "azurerm_public_ip" "app_gateway_ip" {
  count               = var.enable_https ? 1 : 0
  name                = "video-player-gateway-ip"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "video-player-gateway-${random_pet.prefix.id}"
  zones               = ["1", "2", "3"] # Zone-redundant for high availability
  
  tags = {
    environment = "Demo"
    purpose     = "Application Gateway"
  }
}

# Variable to control HTTPS setup
variable "enable_https" {
  description = "Enable HTTPS with Application Gateway"
  type        = bool
  default     = false
}

# Outputs for dynamic IP addresses
output "video_player_public_ip" {
  description = "Public IP address for video player LoadBalancer"
  value       = azurerm_public_ip.video_player_lb.ip_address
}

output "video_player_fqdn" {
  description = "Fully qualified domain name for video player"
  value       = azurerm_public_ip.video_player_lb.fqdn
}

output "app_gateway_public_ip" {
  description = "Public IP address for Application Gateway (if enabled)"
  value       = var.enable_https ? azurerm_public_ip.app_gateway_ip[0].ip_address : null
}

output "app_gateway_fqdn" {
  description = "Fully qualified domain name for Application Gateway (if enabled)"
  value       = var.enable_https ? azurerm_public_ip.app_gateway_ip[0].fqdn : null
}
