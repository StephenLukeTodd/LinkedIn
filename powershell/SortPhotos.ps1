# Specify the source folder containing photos
# Use environment variable to avoid embedding a username
$sourceFolder = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive\Pictures\Unsorted'

# Specify the destination folder for organized photos
$destinationFolder = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive\Pictures\DateSort'

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}

# Get all files in the source folder (including subfolders)
Get-ChildItem -Path $sourceFolder -File -Recurse | ForEach-Object {
    # Get the file's creation year (or modification year if needed)
    $year = $_.CreationTime.Year

    # Create a subfolder for the year if it doesn't exist
    $yearFolder = Join-Path -Path $destinationFolder -ChildPath $year
    if (-not (Test-Path -Path $yearFolder)) {
        New-Item -ItemType Directory -Path $yearFolder | Out-Null
    }

    # Move the file to the year folder
    $destinationPath = Join-Path -Path $yearFolder -ChildPath $_.Name
    Move-Item -Path $_.FullName -Destination $destinationPath -Force
    Write-Host "Moved $($_.Name) to $yearFolder"
}

Write-Host "Photo organization complete!"
