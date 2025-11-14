Import-Module Az
# Connect to Azure
Connect-AzAccount

# Retrieve all resource groups
$resourceGroups = Get-AzResourceGroup

foreach ($rg in $resourceGroups) {
    Write-Host "Processing Resource Group: $($rg.ResourceGroupName)"

    # Stop all VMs in the resource group
    $vms = Get-AzVM -ResourceGroupName $rg.ResourceGroupName
    foreach ($vm in $vms) {
        if ($vm.PowerState -ne 'VM deallocated') {
            Write-Host "Stopping VM: $($vm.Name)"
            Stop-AzVM -Name $vm.Name -ResourceGroupName $rg.ResourceGroupName -Force
        } else {
            Write-Host "VM $($vm.Name) is already deallocated."
        }
    }

    # Deallocate public IPs (optional)
    $publicIPs = Get-AzPublicIpAddress -ResourceGroupName $rg.ResourceGroupName
    foreach ($pip in $publicIPs) {
        Write-Host "Removing Public IP: $($pip.Name)"
        Remove-AzPublicIpAddress -Name $pip.Name -ResourceGroupName $rg.ResourceGroupName -Force
    }
}