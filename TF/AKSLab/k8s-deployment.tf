# Generate Kubernetes deployment file with dynamic values
resource "local_file" "k8s_deployment" {
  content = templatefile("${path.module}/video-app/k8s-deployment-dynamic.yaml", {
    ACR_LOGIN_SERVER       = azurerm_container_registry.default.login_server
    STORAGE_ACCOUNT_NAME   = azurerm_storage_account.default.name
    STORAGE_ACCOUNT_ENDPOINT = azurerm_storage_account.default.primary_blob_endpoint
    RESOURCE_GROUP_NAME    = azurerm_resource_group.default.name
    DNS_LABEL              = "video-player-${random_pet.prefix.id}"
    LOAD_BALANCER_IP       = azurerm_public_ip.video_player_lb.ip_address
  })
  filename = "${path.module}/video-app/k8s-deployment-generated.yaml"
}

# Generate Kubernetes secrets file
resource "local_sensitive_file" "k8s_secrets" {
  content = templatefile("${path.module}/video-app/secrets.yaml", {
    STORAGE_CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.default.name};AccountKey=${azurerm_storage_account.default.primary_access_key};EndpointSuffix=core.windows.net"
    AZURE_AD_CLIENT_ID       = azuread_application.video_player.client_id
    AZURE_AD_CLIENT_SECRET   = azuread_service_principal_password.video_player.value
    AZURE_AD_TENANT_ID       = data.azurerm_client_config.current.tenant_id
  })
  filename = "${path.module}/video-app/secrets-generated.yaml"
}

# Output the generated file paths
output "k8s_deployment_file" {
  description = "Path to generated Kubernetes deployment file"
  value       = local_file.k8s_deployment.filename
}

output "k8s_secrets_file" {
  description = "Path to generated Kubernetes secrets file"
  value       = local_sensitive_file.k8s_secrets.filename
}
