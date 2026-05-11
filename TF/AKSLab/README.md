# Azure Kubernetes Service (AKS) Lab with Secure Storage Integration

This Terraform configuration deploys a complete AKS lab environment with automated service principal creation, Azure Key Vault integration, secure blob storage, and network whitelisting for storage access.

## Overview

The configuration automatically:
- Creates a new Azure AD application and service principal
- Generates a secure password for the service principal
- Stores all credentials in Azure Key Vault
- Deploys an AKS cluster using the generated service principal
- Creates a secure blob storage account with enterprise-grade security
- Sets up custom Virtual Network with dynamic IP allocation
- Whitelists AKS cluster subnet for secure storage access
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
- ✅ **Network Integration**: Custom VNet with dynamic IP allocation
- ✅ **Storage Whitelisting**: AKS subnet specifically whitelisted for storage access
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
- **Virtual Network**: `{random-prefix}-vnet` with dynamic IP allocation
- **AKS Subnet**: `aks-subnet` with proper delegation for AKS
- **Azure AD Application**: `{random-prefix}-aks-sp`
- **Service Principal**: With automatically generated credentials
- **Key Vault**: `{random-prefix}-kv` with stored secrets
- **AKS Cluster**: `{random-prefix}-aks` with custom networking
- **Storage Account**: `{random-prefix}-sa` with network whitelisting

### Key Vault Secrets
- `aks-sp-app-id`: Service principal client ID
- `aks-sp-app-password`: Service principal password
- `aks-sp-tenant-id`: Azure AD tenant ID

### Storage Account Features
- **Secure Access**: Network rules deny all traffic except AKS subnet
- **Network Whitelisting**: AKS cluster subnet explicitly allowed
- **Containers**: `data` and `logs` containers (private access)
- **Data Protection**: Simplified configuration without versioning or retention policies
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

## Network Configuration

### Dynamic IP Allocation
- **Virtual Network**: Uses randomly generated private IP space (e.g., `42.0.0.0/16`)
- **AKS Subnet**: Allocated as `${random_octet}.1.0/24` (e.g., `42.1.0/24`)
- **Avoids Conflicts**: No hardcoded IP addresses, suitable for shared environments

### Storage Access Security
- **Default Deny**: Storage account denies all network access by default
- **AKS Whitelist**: Only the AKS cluster subnet can access storage
- **Azure Services Bypass**: Management operations still allowed

## Configuration Files

| File | Purpose |
|------|---------|
| `main.tf` | Core infrastructure, service principal creation, and outputs |
| `network.tf` | Virtual Network and subnet configuration with dynamic IP allocation |
| `aks-cluster.tf` | AKS cluster configuration with custom networking |
| `aks-kv.tf` | Key Vault creation and credential storage |
| `storage-account.tf` | Secure blob storage account with network whitelisting |
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
3. **Network Isolation**: Storage account access restricted to AKS subnet only
4. **Dynamic IP Allocation**: No hardcoded network addresses
5. **Access Control**: Service principal has appropriate Key Vault and Storage permissions
6. **Audit Trail**: Key Vault provides access logging
7. **No Hardcoded Secrets**: Everything generated and stored dynamically
8. **Storage Security**: Network rules with default deny, explicit AKS whitelist
9. **Encryption Enforcement**: TLS 1.2 required, HTTPS-only access
10. **Identity-Based Auth**: Microsoft Entra ID authentication (shared keys disabled)
11. **Simplified Configuration**: Streamlined storage without complex data protection features

## AKS Cluster Specifications

- **Kubernetes Version**: 1.34
- **Node Pool**: 1 node (configurable)
- **VM Size**: Standard_D2s_v3
- **OS Disk**: 30 GB
- **Network Plugin**: Azure CNI with custom VNet
- **Subnet**: Dedicated AKS subnet with proper delegation
- **Storage Profile**: Blob driver enabled for persistent volumes
- **Authentication**: Service principal with Key Vault-stored credentials
- **RBAC**: Enabled
- **OIDC Issuer**: Enabled
- **Tags**: Environment: "Demo"

## Storage Account Specifications

- **Account Type**: StorageV2 (Standard LRS)
- **Network Security**: Default deny with AKS subnet whitelisted
- **Access**: Private containers, no public network access
- **Authentication**: Microsoft Entra ID only (shared keys disabled)
- **Encryption**: TLS 1.2 required, HTTPS-only access
- **Containers**: `data` and `logs` (private access)
- **Data Protection**: Simplified configuration without versioning or retention policies
- **RBAC**: Service principal has multiple roles (Blob Data Contributor, Queue Data Contributor, Storage Account Contributor)
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
