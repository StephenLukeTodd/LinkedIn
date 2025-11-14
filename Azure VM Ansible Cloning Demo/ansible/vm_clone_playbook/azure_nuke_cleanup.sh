
# Optional: Set a specific subscription if needed
# Set-AzContext -SubscriptionId "<your-subscription-id>"

# Get all resource groups
$resourceGroups = Get-AzResourceGroup

foreach ($rg in $resourceGroups) {
    Write-Host "Deleting resource group: $($rg.ResourceGroupName)" -ForegroundColor Red
    Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob
}

#az group list --query "[].name" -o tsv | while read -r rg; do echo "Deleting $rg..."; az group delete --name "$rg" --yes --no-wait; done
#PS One Liner: Get-AzResourceGroup | ForEach-Object { Write-Host "Deleting $($_.ResourceGroupName)"; Remove-AzResourceGroup -Name $_.ResourceGroupName -Force -AsJob }