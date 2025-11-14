# Define multiple copy jobs as pairs of Source/Destination
$Jobs = @(
    @{ Source = "D:\Emulation"; Destination = "E:\Emulation" }
    @{ Source = "D:\Mods";      Destination = "E:\Mods" }
    @{ Source = "D:\pcports";   Destination = "E:\pcports" }
)

foreach ($Job in $Jobs) {
    $Source      = $Job.Source
    $Destination = $Job.Destination

    Write-Host ">>> Mirroring $Source to $Destination"

    # 1. Ensure destination exists
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    # 2. Copy new/updated files
    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
        $target = $_.FullName.Replace($Source, $Destination)
        $targetDir = Split-Path $target
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        if (-not (Test-Path -LiteralPath $target) -or ($_.LastWriteTime -gt (Get-Item $target).LastWriteTime)) {
            Copy-Item -Path $_.FullName -Destination $target -Force
            Write-Host "Copied: $target"
        }
    }

    # 3. Remove files that no longer exist in source
    Get-ChildItem -Path $Destination -Recurse -File | ForEach-Object {
        $sourceFile = $_.FullName.Replace($Destination, $Source)
        if (-not (Test-Path -LiteralPath $sourceFile)) {
            Remove-Item -Path $_.FullName -Force
            Write-Host "Removed: $($_.FullName)"
        }
    }

    # 4. Remove empty directories
    Get-ChildItem -Path $Destination -Recurse -Directory | Sort-Object FullName -Descending | ForEach-Object {
        if (-not (Get-ChildItem -Path $_.FullName)) {
            Remove-Item -Path $_.FullName -Force
            Write-Host "Removed empty folder: $($_.FullName)"
        }
    }

    Write-Host ">>> Mirror complete for $Source!"
    Write-Host "-------------------------------------------"
}