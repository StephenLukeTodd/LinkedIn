#!/bin/bash

# Ensure the script is run with the CSV file as an argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path_to_csv_file>"
  exit 1
fi

CSV_FILE="$1"

# Check if the CSV file exists
if [ ! -f "$CSV_FILE" ]; then
  echo "Error: File '$CSV_FILE' not found!"
  exit 1
fi

# Read each directory path from the CSV file
while IFS=, read -r directory_path; do
  # Remove any surrounding whitespace from the directory path
  directory_path=$(echo "$directory_path" | xargs)
  
  # Skip empty lines
  if [ -z "$directory_path" ]; then
    continue
  fi

  # Check if the directory exists
  if [ ! -d "$directory_path" ]; then
    echo "Error: Directory '$directory_path' not found. Skipping."
    continue
  fi

  echo "Processing directory: $directory_path"

  # Find all subfolders and move their contents to the parent folder
  find "$directory_path" -mindepth 2 -type f -exec mv -t "$directory_path" {} +

  # Remove empty subdirectories
  find "$directory_path" -mindepth 1 -type d -empty -exec rmdir {} +

  echo "Finished processing: $directory_path"
done < "$CSV_FILE"

echo "All directories processed."
