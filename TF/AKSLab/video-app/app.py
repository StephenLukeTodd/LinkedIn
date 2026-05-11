from flask import Flask, render_template, request, jsonify
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential
import os
import random
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Azure Storage Configuration
STORAGE_ACCOUNT_NAME = os.getenv('STORAGE_ACCOUNT_NAME')
CONTAINER_NAME = os.getenv('CONTAINER_NAME', 'data')

def get_blob_service_client():
    """Get Azure Blob Service Client using managed identity or connection string"""
    try:
        # Try managed identity first (for Azure deployment)
        credential = DefaultAzureCredential()
        account_url = f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net"
        return BlobServiceClient(account_url=account_url, credential=credential)
    except Exception:
        # Fallback to connection string (for local development)
        connection_string = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
        if connection_string:
            return BlobServiceClient.from_connection_string(connection_string)
        else:
            raise Exception("No valid Azure Storage authentication method found")

def get_mp4_files():
    """Get list of MP4 files from Azure Blob Storage"""
    try:
        blob_service_client = get_blob_service_client()
        container_client = blob_service_client.get_container_client(CONTAINER_NAME)
        
        mp4_files = []
        for blob in container_client.list_blobs():
            if blob.name.lower().endswith('.mp4'):
                mp4_files.append({
                    'name': blob.name,
                    'url': f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net/{CONTAINER_NAME}/{blob.name}",
                    'size': blob.size
                })
        
        return mp4_files
    except Exception as e:
        print(f"Error fetching MP4 files: {e}")
        return []

def get_blob_sas_url(blob_name):
    """Generate SAS URL for blob access"""
    try:
        from azure.storage.blob import generate_blob_sas, BlobSasPermissions
        from datetime import datetime, timedelta
        
        # Get account key for SAS token generation
        connection_string = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
        if connection_string:
            blob_service_client = BlobServiceClient.from_connection_string(connection_string)
            
            # Generate SAS token valid for 1 hour
            sas_token = generate_blob_sas(
                account_name=STORAGE_ACCOUNT_NAME,
                container_name=CONTAINER_NAME,
                blob_name=blob_name,
                account_key=blob_service_client.credential.account_key,
                permission=BlobSasPermissions(read=True),
                expiry=datetime.utcnow() + timedelta(hours=1)
            )
            
            return f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net/{CONTAINER_NAME}/{blob_name}?{sas_token}"
        else:
            # Return regular URL if no connection string (managed identity)
            return f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net/{CONTAINER_NAME}/{blob_name}"
    except Exception as e:
        print(f"Error generating SAS URL: {e}")
        return f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net/{CONTAINER_NAME}/{blob_name}"

@app.route('/')
def index():
    """Main page with video player"""
    return render_template('index.html')

@app.route('/api/videos')
def list_videos():
    """API endpoint to get list of MP4 files"""
    mp4_files = get_mp4_files()
    return jsonify({
        'videos': mp4_files,
        'count': len(mp4_files)
    })

@app.route('/api/random-video')
def random_video():
    """API endpoint to get a random MP4 file"""
    mp4_files = get_mp4_files()
    
    if not mp4_files:
        return jsonify({'error': 'No MP4 files found'}), 404
    
    selected_video = random.choice(mp4_files)
    
    # Generate SAS URL for secure access
    video_url = get_blob_sas_url(selected_video['name'])
    
    return jsonify({
        'video': {
            'name': selected_video['name'],
            'url': video_url,
            'size': selected_video['size']
        }
    })

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
