# Specify the source and destination folders
# Use the current user's profile rather than embedding a username
$sourceFolder = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive\Pictures\Screenshots'
$destinationFolder = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive\Pictures\Unsorted'

Get-ChildItem -Path $sourceFolder -Recurse -File | Move-Item -Destination $destinationFolder
