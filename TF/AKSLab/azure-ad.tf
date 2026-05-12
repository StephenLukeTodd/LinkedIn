# Azure AD Application for Video Player Authentication
resource "azuread_application" "video_player" {
  display_name = "Video Player App"
  sign_in_audience = "AzureADMyOrg"
  
  web {
    redirect_uris = ["http://${azurerm_public_ip.video_player_lb.fqdn}/getAToken"]
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
  
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "video_player" {
  client_id = azuread_application.video_player.client_id
}

resource "azuread_service_principal_password" "video_player" {
  service_principal_id = azuread_service_principal.video_player.object_id
  end_date_relative     = "8760h" # 1 year
}

# Variables
variable "https_cert_password" {
  description = "Password for the SSL certificate"
  type        = string
  default     = "YourSecurePassword123!"
}

# Outputs
output "azure_ad_client_id" {
  value = azuread_application.video_player.client_id
}

output "azure_ad_client_secret" {
  value     = azuread_service_principal_password.video_player.value
  sensitive = true
}

output "azure_ad_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
