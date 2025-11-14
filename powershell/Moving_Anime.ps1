# Path to the CSV file
# Avoid embedding absolute drive paths; set a placeholder or use an environment/relative path
$csvPath = Join-Path -Path '<CSV_PATH>' -ChildPath 'FolderList.csv'

# Import the CSV file
$folders = Import-Csv -Path $csvPath

foreach ($folder in $folders) {
    # Get the folder path from the CSV
    $rootFolder = $folder.FolderPath

    # Check if the folder exists
    if (Test-Path -Path $rootFolder) {
        Write-Host "Processing folder: $rootFolder"

        # Get all files in subfolders
        $files = Get-ChildItem -Path $rootFolder -Recurse -File

        foreach ($file in $files) {
            try {
                # Construct the destination path in the root folder
                $destination = Join-Path -Path $rootFolder -ChildPath $file.Name

                # Handle duplicates by appending a number if necessary
                $counter = 1
                while (Test-Path $destination) {
                    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                    $extension = [System.IO.Path]::GetExtension($file.Name)
                    $destination = Join-Path -Path $rootFolder -ChildPath ("$baseName-$counter$extension")
                    $counter++
                }

                # Move the file to the root folder
                Move-Item -Path $file.FullName -Destination $destination -ErrorAction Stop
                Write-Host "Moved: $($file.FullName) to $destination"
            } catch {
                Write-Host "Error moving $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Folder does not exist: $rootFolder" -ForegroundColor Yellow
    }
}
