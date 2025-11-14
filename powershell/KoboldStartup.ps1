# Use environment profile to avoid committing a specific username/path
$exePath = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive\Desktop\AI\koboldcpp_rocm.exe'
$configPath = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive\Desktop\AI\Models\settings.kcpps'
& "$exePath" --config "$configPath"
