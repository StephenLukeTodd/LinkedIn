# Use placeholders for local drives/paths to avoid exposing machine-specific layout
$source = "<SRC_GAMES_DIR>"            # set locally before running
$destination = "<DEST_GAMES_DIR>"      # set locally before running
$logFile = "<LOG_FILE_PATH>"           # set locally before running

# Check if log file exists, create if not
if (-not (Test-Path $logFile)) {
    New-Item -ItemType File -Path $logFile
}

Get-ChildItem -Path $source -Recurse -File | ForEach-Object {
    $filePath = $_.FullName
    $fileName = $_.Name
    try {
        Copy-Item -Path $filePath -Destination $destination -ErrorAction Stop
        $logMessage = "$(Get-Date) - SUCCESS: Copied '$fileName' to '$destination'."
        Write-Output "Successful copied";
    } catch {
        $logMessage = "$(Get-Date) - ERROR: Failed to copy '$fileName'. Error: $_"
        Write-Output "Failed to copy"; 
    }
    Add-Content -Path $logFile -Value $logMessage
}

Write-Host "Operation completed. Check the log file at $logFile for details."


#Games - <SRC_GAMES_DIR> to <DEST_GAMES_DIR>
#DLC and Updates - <SRC_DLC_DIR> to <DEST_DLC_DIR>