#!/usr/bin/env python3
"""
Video Upload Script for Azure Storage
Uploads all MP4 files from Desktop/MP4s folder to Azure Storage Account
"""

import os
import sys
from pathlib import Path
from azure.storage.blob import BlobServiceClient
from azure.core.exceptions import AzureError

# Configuration
STORAGE_ACCOUNT_NAME = "welcomellamasa"
CONTAINER_NAME = "data"
MP4_FOLDER = Path.home() / "Desktop" / "MP4s"

def get_connection_string():
    """Get storage connection string from user input or environment"""
    # Option 1: Try environment variable
    conn_str = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
    if conn_str:
        return conn_str
    
    # Option 2: Get from user input
    print("Azure Storage Connection String not found in environment.")
    print("You can get this from:")
    print("1. Terraform output: terraform output -raw storage_account_primary_endpoint")
    print("2. Azure Portal → Storage Account → Access Keys")
    print("3. Key Vault: welcome-llama-kv → storage-account-endpoint")
    
    conn_str = input("\nEnter your Azure Storage Connection String: ").strip()
    return conn_str

def sanitize_filename(filename):
    """Remove illegal characters from filename for Azure Storage"""
    import re
    # Azure Storage doesn't allow: \ / : * ? " < > | and control characters
    # Replace them with underscores
    return re.sub(r'[\\:*?"<>|]', '_', filename)

def upload_videos():
    """Upload all MP4 files from Desktop/MP4s folder to Azure Storage"""
    
    # Check if MP4s folder exists
    if not MP4_FOLDER.exists():
        print(f"❌ Error: MP4s folder not found at {MP4_FOLDER}")
        print("Please create the folder and add your MP4 files to it.")
        return False
    
    # Get connection string
    try:
        connection_string = get_connection_string()
    except KeyboardInterrupt:
        print("\n❌ Upload cancelled.")
        return False
    
    # Initialize blob service client
    try:
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        container_client = blob_service_client.get_container_client(CONTAINER_NAME)
        print(f"✅ Connected to storage account: {STORAGE_ACCOUNT_NAME}")
    except AzureError as e:
        print(f"❌ Error connecting to Azure Storage: {e}")
        return False
    
    # Get all MP4 files
    mp4_files = list(MP4_FOLDER.glob("*.mp4"))
    mp4_files.extend(MP4_FOLDER.glob("*.MP4"))  # Also check uppercase
    
    if not mp4_files:
        print(f"❌ No MP4 files found in {MP4_FOLDER}")
        print("Please add some MP4 files to the folder and try again.")
        return False
    
    print(f"📹 Found {len(mp4_files)} video files to upload:")
    for file in mp4_files:
        print(f"   - {file.name}")
    
    # Upload files
    success_count = 0
    error_count = 0
    uploaded_names = set()  # Track uploaded names to handle duplicates
    
    print("\n🚀 Starting upload...")
    
    for video_file in mp4_files:
        try:
            # Get file size for progress
            file_size = video_file.stat().st_size
            original_name = video_file.name
            
            # Sanitize filename
            safe_name = sanitize_filename(original_name)
            
            # Handle duplicates by adding timestamp
            if safe_name in uploaded_names:
                import time
                name_without_ext = safe_name.rsplit('.', 1)[0]
                extension = safe_name.rsplit('.', 1)[1] if '.' in safe_name else 'mp4'
                safe_name = f"{name_without_ext}_{int(time.time())}.{extension}"
            
            print(f"📤 Uploading {original_name} ({file_size:,} bytes)...")
            if original_name != safe_name:
                print(f"   → Renamed to: {safe_name}")
            
            # Upload with progress indication
            blob_client = container_client.get_blob_client(safe_name)
            
            with open(video_file, "rb") as data:
                blob_client.upload_blob(data, overwrite=True)
            
            print(f"✅ Uploaded: {safe_name}")
            success_count += 1
            uploaded_names.add(safe_name)
            
        except AzureError as e:
            print(f"❌ Error uploading {original_name}: {e}")
            error_count += 1
        except Exception as e:
            print(f"❌ Unexpected error uploading {original_name}: {e}")
            error_count += 1
    
    # Summary
    print(f"\n📊 Upload Summary:")
    print(f"✅ Successfully uploaded: {success_count} files")
    print(f"❌ Failed uploads: {error_count} files")
    
    if success_count > 0:
        print(f"\n🌐 Your videos are now available at:")
        print(f"http://20.245.130.231")
        print(f"http://video-player-welcome-llama.westus.cloudapp.azure.com")
    
    return error_count == 0

def list_uploaded_videos():
    """List all videos currently in the storage container"""
    try:
        connection_string = get_connection_string()
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        container_client = blob_service_client.get_container_client(CONTAINER_NAME)
        
        print(f"\n📋 Videos currently in storage container '{CONTAINER_NAME}':")
        blob_list = container_client.list_blobs()
        
        videos = [blob for blob in blob_list if blob.name.lower().endswith('.mp4')]
        
        if not videos:
            print("   No videos found in storage.")
        else:
            for video in videos:
                size_mb = video.size / (1024 * 1024)
                print(f"   - {video.name} ({size_mb:.1f} MB)")
                
    except Exception as e:
        print(f"❌ Error listing videos: {e}")

if __name__ == "__main__":
    print("🎬 Azure Video Upload Tool")
    print("=" * 40)
    
    if len(sys.argv) > 1 and sys.argv[1] == "--list":
        list_uploaded_videos()
    else:
        upload_videos()
