# Project Cringe Machine (AKS Lab)

Project Cringe Machine is a collection of Instagram reels pulled from a storage account to play randomly on a website for my enjoyment.

This Terraform configuration deploys a complete AKS lab environment to run the app, including Azure AD authentication, dynamic IP configuration, and security-focused defaults.

## Overview

The configuration automatically:
- Creates a new Azure AD application and service principal
- Generates secure credentials and stores them in Azure Key Vault
- Deploys an AKS cluster with custom networking
- Creates secure blob storage with network whitelisting
- Builds and deploys Project Cringe Machine with Azure AD authentication
- Configures dynamic IP addresses for public access
- Implements proper secrets management and security best practices

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure AD      │    │  Azure Key Vault │    │      AKS        │    │  Blob Storage   │
│                 │    │                  │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │Project Cringe│ │───▶│ │ App Secrets  │ │    │ │ Project Cringe│ │───▶│ │  Video Data  │ │
│ │   Machine    │ │    │ │ Storage Creds│ │◀───│ │  Container  │ │    │ │  Containers  │ │
│ │             │ │    │ │ AD Credentials│ │    │ │             │ │    │ │             │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                  │    │                 │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └─────────────────┘
         │                                               │
         │                                               │
         ▼                                               ▼
┌─────────────────┐                         ┌─────────────────┐
│  Public Access  │                         │  Container      │
│  (Dynamic IP)   │                         │  Registry       │
│                 │                         │                 │
│ ┌─────────────┐ │                         │ ┌─────────────┐ │
│ │ LoadBalancer│ │◀────────────────────────│ │Secure Images │ │
│ │   Service   │ │                         │ │             │ │
│ └─────────────┘ │                         │ └─────────────┘ │
└─────────────────┘                         └─────────────────┘
```

## Features

### Infrastructure Features
- ✅ **Zero Manual Setup**: Everything created automatically
- ✅ **Dynamic IP Configuration**: Static public IP with dynamic DNS for consistent access
- ✅ **Secure Credential Generation**: Service principal with strong passwords
- ✅ **Key Vault Storage**: All credentials stored securely
- ✅ **Network Integration**: Custom VNet with dynamic IP allocation
- ✅ **Storage Whitelisting**: AKS subnet specifically whitelisted for storage access
- ✅ **Random Naming**: Resources use random prefixes for uniqueness
- ✅ **Proper Access Control**: Service principal has appropriate permissions

### Application Features
- ✅ **Azure AD Authentication**: Enterprise-grade single sign-on
- ✅ **Secure Video Streaming**: Protected video access with SAS URLs
- ✅ **Modern UI**: Professional interface with Bootstrap styling
- ✅ **Session Management**: Secure encrypted sessions with timeout
- ✅ **Container Security**: Non-root user, health checks, minimal attack surface
- ✅ **API Security**: All endpoints protected behind authentication

### Security Features
- ✅ **Enterprise Authentication**: Azure AD integration with MSAL
- ✅ **Network Security**: Storage access restricted to AKS subnet only
- ✅ **Secrets Management**: Kubernetes secrets for sensitive data
- ✅ **Data Protection**: Versioning, retention policies, and encryption enabled
- ✅ **Audit Trail**: Key Vault provides access logging
- ✅ **No Hardcoded Secrets**: Everything generated and stored dynamically

## Prerequisites

- Azure CLI installed and authenticated
- Terraform installed
- Docker installed (for building container images)
- Appropriate Azure permissions to create:
  - Resource groups
  - AKS clusters
  - Azure AD applications and service principals
  - Key Vaults
  - Container registries

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

### 4. Build and Deploy the Project Cringe Machine

```bash
# Navigate to the app directory
cd video-player

# Build the secure Docker image
docker build --platform linux/amd64 -t project-cringe-machine-secure .

# Tag and push to ACR (use outputs from Terraform)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
docker tag project-cringe-machine-secure $ACR_LOGIN_SERVER/video-player:secure
docker push $ACR_LOGIN_SERVER/video-player:secure

# Deploy to Kubernetes
kubectl apply -f k8s-deployment-generated.yaml
kubectl apply -f secrets-generated.yaml
```

### 5. Access the Application

Get the public IP or FQDN from Terraform outputs:

```bash
# Get the public IP
terraform output video_player_public_ip

# Get the FQDN
terraform output video_player_fqdn
```

Visit `http://<PUBLIC_IP>` or `http://<FQDN>` to access the Project Cringe Machine.

## What Gets Created

### Azure Resources
- **Resource Group**: `MooRG` (configurable)
- **Virtual Network**: `{random-prefix}-vnet` with dynamic IP allocation
- **AKS Subnet**: `aks-subnet` with proper delegation for AKS
- **Gateway Subnet**: `gateway-subnet` for Application Gateway (optional)
- **Azure AD Application**: `{random-prefix}-aks-sp`
- **Service Principal**: With automatically generated credentials
- **Key Vault**: `{random-prefix}-kv` with stored secrets
- **AKS Cluster**: `{random-prefix}-aks` with custom networking
- **Storage Account**: `{random-prefix}-sa` with network whitelisting
- **Container Registry**: `{random-prefix}-acr` for secure image storage
- **Public IP**: Static IP for LoadBalancer with dynamic DNS

### Application Components
- **Project Cringe Machine Flask App**: Secure web application with Azure AD authentication
- **Docker Container**: Optimized multi-stage build with security best practices
- **Kubernetes Deployment**: Auto-scaling deployment with health checks
- **LoadBalancer Service**: Public access with static IP
- **Kubernetes Secrets**: Secure storage for credentials

### Key Vault Secrets
- `aks-sp-app-id`: Service principal client ID
- `aks-sp-app-password`: Service principal password
- `aks-sp-tenant-id`: Azure AD tenant ID
- `storage-account-name`: Storage account name
- `storage-account-endpoint`: Storage account endpoint
- `acr-login-server`: Container registry login server
- `acr-username`: Container registry username
- `acr-password`: Container registry password

### Storage Account Features
- **Secure Access**: Network rules deny all traffic except AKS subnet
- **Network Whitelisting**: AKS cluster subnet explicitly allowed
- **Containers**: `data` and `logs` containers (private access)
- **Data Protection**: Simplified configuration without versioning or retention policies
- **Encryption**: TLS 1.2 required, HTTPS only
- **Authentication**: Microsoft Entra ID only (shared keys disabled)

## Project Cringe Machine Application

### Features
- **Azure AD Authentication**: Secure login with Microsoft accounts
- **Video Streaming**: Random video selection from Azure Blob Storage
- **SAS Token Security**: Time-limited secure access to video files
- **Responsive UI**: Modern interface with Bootstrap styling
- **User Dashboard**: Display authenticated user information
- **Secure Logout**: Proper session termination

### API Endpoints
- `GET /`: Main page (requires authentication)
- `GET /login`: Login page
- `GET /logout`: Logout endpoint
- `GET /getAToken`: Azure AD callback endpoint
- `GET /api/random-video`: Get random video with SAS URL
- `GET /api/videos`: List all available videos
- `GET /health`: Health check endpoint

### Environment Variables
- `AZURE_STORAGE_ACCOUNT_NAME`: Storage account name
- `AZURE_STORAGE_CONTAINER_NAME`: Container name (default: data)
- `AZURE_STORAGE_CONNECTION_STRING`: Storage connection string
- `AZURE_AD_CLIENT_ID`: Azure AD application client ID
- `AZURE_AD_CLIENT_SECRET`: Azure AD application client secret
- `AZURE_AD_TENANT_ID`: Azure AD tenant ID

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
| `acr.tf` | Azure Container Registry for secure image storage |
| `azure-ad.tf` | Azure AD application for video player authentication |
| `public-ip.tf` | Public IP configuration for LoadBalancer service |
| `k8s-deployment.tf` | Kubernetes deployment template generation |
| `variables.tf` | Input variables (resource group name and location) |

### Video Player App Files
| File | Purpose |
|------|---------|
| `video-player/app.py` | Flask application |
| `video-player/Dockerfile` | Container image build definition |
| `video-player/k8s-deployment-dynamic.yaml` | Kubernetes deployment template |
| `video-player/secrets.yaml` | Kubernetes secrets template |
| `video-player/requirements.txt` | Python dependencies |
| `video-player/templates/` | HTML templates for the web interface |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `resource_group_name` | `MooRG` | Name of the Azure resource group |
| `location` | `westus` | Azure region for deployment |
| `enable_https` | `false` | Enable HTTPS with Application Gateway |

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
| `acr_name` | Name of the Azure Container Registry | ❌ |
| `acr_login_server` | Container registry login server | ❌ |
| `video_player_public_ip` | Public IP address for video player | ❌ |
| `video_player_fqdn` | Fully qualified domain name for video player | ❌ |
| `azure_ad_client_id` | Azure AD application client ID | ❌ |
| `azure_ad_client_secret` | Azure AD application client secret | ✅ |
| `azure_ad_tenant_id` | Azure AD tenant ID | ❌ |

## Security Best Practices

### Infrastructure Security
1. **Automatic Credential Generation**: No manual password creation
2. **Secure Storage**: All secrets stored in Azure Key Vault
3. **Network Isolation**: Storage account access restricted to AKS subnet only
4. **Dynamic IP Allocation**: No hardcoded network addresses
5. **Access Control**: Service principal has appropriate Key Vault and Storage permissions
6. **Audit Trail**: Key Vault provides access logging
7. **No Hardcoded Secrets**: Everything generated and stored dynamically

### Application Security
1. **Azure AD Authentication**: Enterprise-grade single sign-on
2. **Session Management**: Secure encrypted sessions with timeout
3. **SAS Token Security**: Time-limited secure access to video files
4. **Container Security**: Non-root user, health checks, minimal attack surface
5. **API Security**: All endpoints protected behind authentication
6. **Secrets Management**: Kubernetes secrets for sensitive data

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
- Microsoft.ContainerRegistry/*/write

### Common Issues
- **Service Principal Creation**: Requires Azure AD administrator permissions
- **Key Vault Access**: Ensure proper access policies are applied
- **AKS Deployment**: Verify quota and VM size availability in your region
- **Container Registry**: Ensure proper permissions for image push/pull
- **Azure AD Authentication**: Verify redirect URI matches the public IP/FQDN

### Application Issues
- **Authentication Failures**: Check Azure AD app registration and redirect URI
- **Video Access**: Verify storage account permissions and SAS token generation
- **Container Issues**: Check pod logs with `kubectl logs <pod-name>`
- **Network Access**: Verify LoadBalancer service and public IP configuration

## Development

### Local Development
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
cp .env.example .env
# Edit .env with your Azure Storage credentials

# Run locally
python app.py
```

### Building Container Images
```bash
# Build for local testing
docker build -t video-player:secure .

# Build for AKS deployment
docker build --platform linux/amd64 -t video-player:secure .
```

### Kubernetes Debugging
```bash
# Check pod status
kubectl get pods

# View pod logs
kubectl logs <pod-name>

# Describe pod for detailed information
kubectl describe pod <pod-name>

# Check service status
kubectl get services

# Port forward for local testing
kubectl port-forward service/video-player-service 5000:80
```

## Provider Versions

- `azurerm`: ~> 3.116.0
- `azuread`: ~> 2.53.0
- `random`: ~> 3.1.0
- `helm`: ~> 2.0
- `local`: ~> 2.0
- `null`: ~> 3.0

## License

This project is provided as-is for educational and demonstration purposes.
