# Random Video Player

A Flask web application that randomly selects and plays MP4 videos from Azure Blob Storage.

## Features

- 🎲 Random video selection from Azure Blob Storage
- 📋 List all available MP4 files
- 🎬 Built-in HTML5 video player
- 🔐 Secure access using Azure managed identity or connection strings
- 🐳 Docker containerized for easy deployment
- 🏥 Health check endpoints
- 📱 Responsive web interface

## Prerequisites

- Azure Storage Account with MP4 files
- Docker (for local testing)
- Azure CLI (for deployment)

## Configuration

1. Copy the environment file:
```bash
cp .env.example .env
```

2. Edit `.env` with your Azure Storage details:
```env
STORAGE_ACCOUNT_NAME=your_storage_account_name
CONTAINER_NAME=data
AZURE_STORAGE_CONNECTION_STRING=your_connection_string
```

## Local Development

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the application:
```bash
python app.py
```

3. Open http://localhost:5000 in your browser.

## Docker Deployment

1. Build the Docker image:
```bash
docker build -t video-player .
```

2. Run the container:
```bash
docker run -p 5000:5000 --env-file .env video-player
```

## Azure Deployment

The application is designed to work with Azure managed identity when deployed to Azure Container Instances or AKS.

### Using Azure Container Registry

1. Build and push to ACR:
```bash
# Replace with your ACR details
az acr build --registry youracr --image video-player .
```

2. Deploy to Azure Container Instances:
```bash
az container create \
  --resource-group your-resource-group \
  --name video-player \
  --image youracr.azurecr.io/video-player \
  --cpu 1 --memory 1 \
  --ports 5000 \
  --environment-variables STORAGE_ACCOUNT_NAME=your_storage_account_name CONTAINER_NAME=data
```

## API Endpoints

- `GET /` - Main web interface
- `GET /api/videos` - List all MP4 files
- `GET /api/random-video` - Get a random video
- `GET /health` - Health check

## Azure Storage Setup

1. Create a storage account:
```bash
az storage account create \
  --name mystorageaccount \
  --resource-group myresourcegroup \
  --location eastus \
  --sku Standard_LRS
```

2. Create a container:
```bash
az storage container create \
  --name data \
  --account-name mystorageaccount \
  --public-access blob
```

3. Upload MP4 files:
```bash
az storage blob upload \
  --container-name data \
  --file video.mp4 \
  --name video.mp4 \
  --account-name mystorageaccount
```

## Security Notes

- The application supports both connection strings and managed identity
- For production, use managed identity for better security
- SAS tokens are generated with 1-hour expiration for secure video access
- Network access can be restricted through Azure Storage network rules
