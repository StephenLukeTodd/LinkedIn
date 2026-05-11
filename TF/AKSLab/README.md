# Azure Kubernetes Service (AKS) with Automatic Service Principal, Key Vault & Secure Blob Storage

This Terraform configuration deploys an AKS cluster with completely automated service principal creation, Azure Key Vault integration, and secure blob storage. No manual setup or external credentials required.

## Overview

The configuration automatically:
- Creates a new Azure AD application and service principal
- Generates a secure password for the service principal
- Stores all credentials in Azure Key Vault
- Deploys an AKS cluster using the generated service principal
- Creates a secure blob storage account with enterprise-grade security
- Provides secure access to all stored credentials and storage resources

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure AD      │    │  Azure Key Vault │    │      AKS        │    │  Blob Storage   │
│                 │    │                  │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │Application  │ │───▶│ │ aks-sp-app-id│ │    │ │   Cluster   │ │───▶│ │  Containers  │ │
│ │   & SP      │ │    │ │ aks-sp-app-  │ │◀───│ │   (uses SP) │ │    │ │  data/logs   │ │
│ │             │ │    │ │ password     │ │    │ │             │ │    │ │             │ │
│ └─────────────┘ │    │ │ aks-sp-tenant│ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │ │    -id        │ │    │                 │    │                 │
└─────────────────┘    │ └──────────────┘ │    └─────────────────┘    └─────────────────┘
                       │                  │    │                 │
                       └──────────────────┘    │                 │
                                              │                 │
                         ┌──────────────────┐ │                 │
                         │  RBAC Access     │ │                 │
                         │  (Blob Data)     │ │                 │
                         └──────────────────┘ │                 │
                                              │                 │
                                              └─────────────────┘
```

## Features

- ✅ **Zero Manual Setup**: Everything created automatically
- ✅ **Secure Credential Generation**: Service principal with strong password
- ✅ **Key Vault Storage**: All credentials stored securely
- ✅ **Secure Blob Storage**: Enterprise-grade security with private access
- ✅ **Random Naming**: Resources use random prefixes for uniqueness
- ✅ **Proper Access Control**: Service principal has Key Vault and Storage permissions
- ✅ **Clean Outputs**: All credentials and resource info available via Terraform outputs
- ✅ **Data Protection**: Versioning, retention policies, and encryption enabled

## Prerequisites

- Azure CLI installed and authenticated
- Terraform installed
- Appropriate Azure permissions to create:
  - Resource groups
  - AKS clusters
  - Azure AD applications and service principals
  - Key Vaults

## Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Deploy Infrastructure

```bash
terraform apply
```

That's it! The configuration will automatically create everything needed.

## What Gets Created

### Azure Resources
- **Resource Group**: `MooRG` (configurable)
- **Azure AD Application**: `{random-prefix}-aks-sp`
- **Service Principal**: With automatically generated credentials
- **Key Vault**: `{random-prefix}-kv` with stored secrets
- **AKS Cluster**: `{random-prefix}-aks` with 1 node pool
- **Storage Account**: `{random-prefix}-sa` with secure blob storage

### Key Vault Secrets
- `aks-sp-app-id`: Service principal client ID
- `aks-sp-app-password`: Service principal password
- `aks-sp-tenant-id`: Azure AD tenant ID

### Storage Account Features
- **Secure Access**: Public network access disabled
- **Containers**: `data` and `logs` containers (private access)
- **Data Protection**: Versioning, change feed, and 30-day retention
- **Encryption**: TLS 1.2 required, HTTPS only
- **Authentication**: Microsoft Entra ID only (shared keys disabled)

## Accessing Credentials

### Via Terraform Outputs

```bash
# View all outputs (credentials are marked as sensitive)
terraform output

# Show specific credentials
terraform output service_principal_app_id
terraform output service_principal_password
terraform output tenant_id
terraform output key_vault_name
```

### Via Azure CLI

```bash
# Get Key Vault name from Terraform output
KV_NAME=$(terraform output -raw key_vault_name)

# Access individual secrets
az keyvault secret show --vault-name $KV_NAME --name aks-sp-app-id
az keyvault secret show --vault-name $KV_NAME --name aks-sp-app-password
az keyvault secret show --vault-name $KV_NAME --name aks-sp-tenant-id
```

## Configuration Files

| File | Purpose |
|------|---------|
| `main.tf` | Core infrastructure, service principal creation, and outputs |
| `aks-cluster.tf` | AKS cluster configuration using generated service principal |
| `aks-kv.tf` | Key Vault creation and credential storage |
| `storage-account.tf` | Secure blob storage account with enterprise security features |
| `variables.tf` | Input variables (resource group name and location) |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `resource_group_name` | `MooRG` | Name of the Azure resource group |
| `location` | `westus` | Azure region for deployment |

## Outputs

| Output | Description | Sensitive |
|--------|-------------|-----------|
| `service_principal_app_id` | Generated service principal client ID | ✅ |
| `service_principal_password` | Generated service principal password | ✅ |
| `tenant_id` | Azure AD tenant ID | ❌ |
| `key_vault_name` | Name of the Key Vault storing credentials | ❌ |
| `storage_account_name` | Name of the secure blob storage account | ❌ |
| `storage_account_id` | ID of the secure blob storage account | ❌ |
| `storage_account_primary_endpoint` | Primary blob endpoint | ❌ |
| `storage_account_containers` | List of created containers | ❌ |

## Security Features

1. **Automatic Credential Generation**: No manual password creation
2. **Secure Storage**: All secrets stored in Azure Key Vault
3. **Access Control**: Service principal has appropriate Key Vault and Storage permissions
4. **Audit Trail**: Key Vault provides access logging
5. **No Hardcoded Secrets**: Everything generated and stored dynamically
6. **Storage Security**: Public network access disabled, private containers only
7. **Data Protection**: Versioning, change feed, and retention policies enabled
8. **Encryption Enforcement**: TLS 1.2 required, HTTPS-only access
9. **Identity-Based Auth**: Microsoft Entra ID authentication (shared keys disabled)

## AKS Cluster Specifications

- **Kubernetes Version**: 1.34
- **Node Pool**: 1 node (configurable)
- **VM Size**: Standard_D2s_v3
- **OS Disk**: 30 GB
- **Authentication**: Service principal with Key Vault-stored credentials
- **RBAC**: Enabled
- **Tags**: Environment: "Demo"

## Storage Account Specifications

- **Account Type**: StorageV2 (Standard LRS)
- **Access**: Public network disabled, private containers
- **Authentication**: Microsoft Entra ID only (shared keys disabled)
- **Encryption**: TLS 1.2 required, HTTPS-only access
- **Containers**: `data` and `logs` (private access)
- **Data Protection**: Versioning, change feed, 30-day retention
- **RBAC**: Service principal has Storage Blob Data Contributor role
- **Tags**: Environment: "Demo", Security: "high", Purpose: "blob-storage"

## Cleanup

To remove all resources including the service principal and Key Vault:

```bash
terraform destroy
```

## Troubleshooting

### Permission Issues
Ensure your Azure account has permissions for:
- Microsoft.Authorization/*/write
- Microsoft.Resources/*/write
- Microsoft.ContainerService/*/write
- Microsoft.KeyVault/*/write
- Microsoft.Directory/*/write (for service principal creation)

### Common Issues
- **Service Principal Creation**: Requires Azure AD administrator permissions
- **Key Vault Access**: Ensure proper access policies are applied
- **AKS Deployment**: Verify quota and VM size availability in your region

## Provider Versions

- `azurerm`: ~> 3.116.0
- `azuread`: ~> 2.53.0
- `random`: ~> 3.1.0
- `helm`: ~> 2.0
- `local`: ~> 2.0
- `null`: ~> 3.0

## License

This project is provided as-is for educational and demonstration purposes.
