# Azure Kubernetes Service (AKS) with Key Vault Integration

This Terraform configuration deploys an AKS cluster with Azure Key Vault integration for secure credential management. The configuration automatically creates a service principal and stores all credentials in Azure Key Vault.

## Architecture

- **AKS Cluster**: Kubernetes cluster with random naming
- **Azure AD Service Principal**: Automatically created with secure credentials
- **Azure Key Vault**: Secure storage for service principal credentials
- **Key Vault Secrets**: App ID, password, and tenant ID stored automatically

## Features

- **Automatic Service Principal Creation**: No manual setup required
- **Secure Credential Storage**: All credentials stored in Azure Key Vault
- **Zero Manual Configuration**: Everything created via Terraform
- **Proper Access Control**: Service principal has Key Vault access permissions

## Deployment

### 1. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

The deployment will automatically:
- Create a new Azure AD application and service principal
- Generate a secure password
- Store all credentials in Azure Key Vault
- Deploy the AKS cluster using the generated service principal

### 2. Access Credentials

After deployment, you can access the stored credentials:

```bash
# Get outputs (shows service principal credentials)
terraform output

# Access credentials directly from Key Vault
az keyvault secret show --vault-name <key-vault-name> --name aks-sp-app-id
az keyvault secret show --vault-name <key-vault-name> --name aks-sp-app-password
az keyvault secret show --vault-name <key-vault-name> --name aks-sp-tenant-id
```

## Outputs

- `service_principal_app_id`: Generated service principal client ID
- `service_principal_password`: Generated secure password
- `tenant_id`: Your Azure AD tenant ID
- `key_vault_name`: Name of the Key Vault storing credentials

## Files Structure

- `main.tf`: Core infrastructure and service principal creation
- `aks-cluster.tf`: AKS cluster configuration
- `aks-kv.tf`: Key Vault and credential storage
- `variables.tf`: Input variables (resource group and location only)

## Security Benefits

1. **No Hardcoded Credentials**: All secrets generated and stored automatically
2. **Centralized Management**: All credentials in one Key Vault
3. **Access Control**: Fine-grained permissions via Key Vault policies
4. **Audit Trail**: Key Vault provides access logging
5. **Automatic Rotation**: Easy credential rotation via Terraform

## Accessing Secrets in Kubernetes

### Option 1: Direct Pod Access

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-access-pod
spec:
  containers:
  - name: app
    image: your-app-image
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
  - name: secrets-store-inline
    csi:
      driver: secrets-store.csi.x-k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "azure-keyvault-provider"
```

### Option 2: Synced Kubernetes Secrets

The configuration automatically syncs Key Vault secrets to Kubernetes secrets:

- `aks-sp-app-id`
- `aks-sp-app-password`

## Files Structure

- `main.tf`: Core infrastructure (Resource Group, Key Vault, Secrets)
- `aks-cluster.tf`: AKS cluster configuration
- `keyvault-integration.tf`: Key Vault CSI driver and integration
- `variables.tf`: Input variables

## Security Benefits

1. **No Hardcoded Credentials**: Secrets stored securely in Key Vault
2. **Centralized Management**: Single location for all secrets
3. **Access Control**: Fine-grained permissions via Key Vault access policies
4. **Audit Trail**: Key Vault provides access logging
5. **Rotation Support**: Easy secret rotation without redeployment

## Cleanup

```bash
terraform destroy
```

## References

- [Azure Key Vault Provider for Secrets Store CSI Driver](https://github.com/Azure/secrets-store-csi-driver-provider-azure)
- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
