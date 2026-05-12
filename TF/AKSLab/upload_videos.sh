#!/bin/bash

# Azure Video Upload Script
# Uploads all MP4 files from Desktop/MP4s folder to Azure Storage

STORAGE_ACCOUNT="welcomellamasa"
CONTAINER_NAME="data"
MP4_FOLDER="$HOME/Desktop/MP4s"

# Check if MP4s folder exists
if [ ! -d "$MP4_FOLDER" ]; then
    echo "❌ Error: MP4s folder not found at $MP4_FOLDER"
    echo "Please create the folder and add your MP4 files to it."
    exit 1
fi

# Check if there are any MP4 files
if [ -z "$(ls -A "$MP4_FOLDER"/*.mp4 2>/dev/null)" ] && [ -z "$(ls -A "$MP4_FOLDER"/*.MP4 2>/dev/null)" ]; then
    echo "❌ No MP4 files found in $MP4_FOLDER"
    echo "Please add some MP4 files to the folder and try again."
    exit 1
fi

# Get storage account key (you'll need to provide this)
echo "🔑 Getting storage account key..."
STORAGE_KEY=$(az storage account keys list --resource-group MooRG --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv 2>/dev/null)

if [ -z "$STORAGE_KEY" ]; then
    echo "❌ Could not get storage account key automatically."
    echo "Please ensure you're logged into Azure CLI with: az login"
    echo "Or provide the connection string manually."
    exit 1
fi

echo "📹 Found MP4 files to upload:"
find "$MP4_FOLDER" -name "*.mp4" -o -name "*.MP4" | while read -r video_file; do
    echo "   - $(basename "$video_file")"
done

echo ""
echo "🚀 Starting upload..."

# Upload all MP4 files
success_count=0
error_count=0

# Create temp files for counting
success_file=$(mktemp)
error_file=$(mktemp)
echo "0" > "$success_file"
echo "0" > "$error_file"

# Process files one by one to avoid subshell issues
for video_file in "$MP4_FOLDER"/*.mp4 "$MP4_FOLDER"/*.MP4; do
    if [ -f "$video_file" ]; then
        original_name=$(basename "$video_file")
        
        # Sanitize filename: remove illegal characters for Azure Storage
        # Azure Storage doesn't allow: \ / : * ? " < > | and control characters
        safe_name=$(echo "$original_name" | sed 's/[\\:*?"<>|]/_/g')
        
        # Skip files that start with dash (Azure Storage doesn't allow)
        if [[ "$safe_name" == -* ]]; then
            echo "⚠️ Skipping $original_name (starts with dash, not allowed in Azure Storage)"
            current=$(cat "$error_file")
            echo $((current + 1)) > "$error_file"
            continue
        fi
        
        echo "📤 Uploading $original_name"
        if [ "$original_name" != "$safe_name" ]; then
            echo "   → Renamed to: $safe_name"
        fi
        
        if az storage blob upload \
            --account-name "$STORAGE_ACCOUNT" \
            --container-name "$CONTAINER_NAME" \
            --name "$safe_name" \
            --file "$video_file" \
            --overwrite true \
            --no-progress >/dev/null 2>&1; then
            echo "✅ Uploaded: $safe_name"
            current=$(cat "$success_file")
            echo $((current + 1)) > "$success_file"
        else
            echo "❌ Failed to upload: $original_name"
            current=$(cat "$error_file")
            echo $((current + 1)) > "$error_file"
        fi
    fi
done

# Read the counts back
success_count=$(cat "$success_file")
error_count=$(cat "$error_file")

# Clean up temp files
rm -f "$success_file" "$error_file"

echo ""
echo "📊 Upload Summary:"
echo "✅ Successfully uploaded: $success_count files"
echo "❌ Failed uploads: $error_count files"

if [ $success_count -gt 0 ]; then
    echo ""
    echo "🌐 Your videos are now available at:"
    echo "http://20.245.130.231"
    echo "http://video-player-welcome-llama.westus.cloudapp.azure.com"
fi
