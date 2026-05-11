# Azure Kubernetes Service (AKS) with Key Vault Integration

This Terraform configuration deploys an AKS cluster with Azure Key Vault integration for secure credential management.

## Architecture

- **AKS Cluster**: Kubernetes cluster with random naming
- **Azure Key Vault**: Secure storage for service principal credentials
- **Key Vault CSI Driver**: Enables pods to access Key Vault secrets
- **Secret Provider Class**: Kubernetes resource for Key Vault access

## Setup Instructions

### 1. Update terraform.tfvars

Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your values:

```hcl
appId     = "your-service-principal-app-id"
password  = "your-service-principal-password"
tenant_id = "your-azure-ad-tenant-id"
```

### 2. Get your Azure AD Tenant ID

```bash
az account show --query tenantId -o tsv
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

## Key Vault Integration Features

- **Secure Storage**: Service principal credentials stored in Azure Key Vault
- **Automatic Rotation**: Secrets can be rotated automatically
- **Kubernetes Integration**: Secrets synced as Kubernetes secrets
- **Pod Access**: Pods can access Key Vault secrets directly via CSI driver

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
- `terraform.tfvars.example`: Example configuration file

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
