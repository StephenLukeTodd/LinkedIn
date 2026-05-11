# =============================================================================
# Azure Key Vault Integration for AKS
# =============================================================================

# =============================================================================
# Azure Key Vault for Secure Credential Storage
# =============================================================================

resource "azurerm_key_vault" "default" {
  name                        = "${random_pet.prefix.id}-kv"
  location                    = azurerm_resource_group.default.location
  resource_group_name         = azurerm_resource_group.default.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = false

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.appId

    secret_permissions = [
      "Get",
      "List", 
      "Set",
      "Delete",
      "Recover"
    ]
  }
}

# Store service principal credentials securely in Key Vault
resource "azurerm_key_vault_secret" "app_id" {
  name         = "aks-sp-app-id"
  value        = var.appId
  key_vault_id = azurerm_key_vault.default.id
}

resource "azurerm_key_vault_secret" "app_password" {
  name         = "aks-sp-app-password"
  value        = var.password
  key_vault_id = azurerm_key_vault.default.id
}

# =============================================================================
# AKS Key Vault Integration
# =============================================================================

# Enable Key Vault Secrets Provider extension on AKS cluster
resource "azurerm_kubernetes_cluster_extension" "keyvault_provider" {
  name           = "azure-keyvault-secrets-provider"
  cluster_id     = azurerm_kubernetes_cluster.default.id
  extension_type = "Microsoft.AzureKeyVaultSecretsProvider"
}

# Generate SecretProviderClass YAML for Key Vault access
resource "local_file" "secret_provider_class" {
  content = <<-EOF
    apiVersion: secrets-store.csi.x-k8s.io/v1
    kind: SecretProviderClass
    metadata:
      name: azure-keyvault-provider
      namespace: default
    spec:
      provider: azure
      parameters:
        useVMManagedIdentity: "false"
        userAssignedIdentityID: ""
        keyvaultName: "${azurerm_key_vault.default.name}"
        objects: |
          array:
            - |
              objectName: aks-sp-app-id
              objectType: secret
              objectVersion: ""
            - |
              objectName: aks-sp-app-password
              objectType: secret
              objectVersion: ""
        tenantId: "${var.tenant_id}"
  EOF
  
  filename = "${path.module}/secret-provider-class.yaml"
}

resource "null_resource" "apply_instructions" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================================"
      echo "Key Vault Integration Setup Complete!"
      echo "============================================================================"
      echo "Next steps:"
      echo "1. Get cluster credentials: az aks get-credentials --resource-group ${azurerm_resource_group.default.name} --name ${azurerm_kubernetes_cluster.default.name}"
      echo "2. Apply SecretProviderClass: kubectl apply -f secret-provider-class.yaml"
      echo "3. Verify secrets: kubectl get secrets"
      echo "============================================================================"
    EOT
  }

  depends_on = [
    local_file.secret_provider_class,
    azurerm_kubernetes_cluster_extension.keyvault_provider
  ]
}

# Helm provider configuration for Key Vault CSI driver
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

# Install Key Vault CSI driver via Helm chart
resource "helm_release" "keyvault_csi_driver" {
  name       = "csi-secrets-store-provider-azure"
  repository = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart      = "csi-secrets-store-provider-azure"
  namespace  = "kube-system"
  version    = "1.6.1"

  depends_on = [
    azurerm_kubernetes_cluster.default
  ]
}
