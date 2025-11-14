#!/bin/bash

set -e

# Ensure you're logged into Azure
az account show &>/dev/null || az login


echo "📦 Existing resource groups:"
az group list --query "[].name" -o tsv

read -p "Enter the name of the resource group you want to delete: " selected_rg
rgs=("$selected_rg")

for RG in "${rgs[@]}"; do
  echo ""
  read -p "⚠️ Are you sure you want to delete resource group '$RG' and all its resources? (yes/no): " confirm

  if [[ "$confirm" == "yes" ]]; then
    echo "🧨 Deleting virtual machines in '$RG'..."
    az vm list --resource-group "$RG" --query "[].name" -o tsv | while read -r vm_name; do
      echo "Deleting VM: $vm_name"
      az vm delete --resource-group "$RG" --name "$vm_name" --yes --no-wait
    done

    echo "🗑️ Deleting resource group '$RG'..."
    az group delete --name "$RG" --yes --no-wait
    echo "✅ Deletion of '$RG' initiated."

    echo "🧹 Cleaning up deprovisioned resources for '$RG'..."
    az resource list --resource-group "$RG" --query "[?properties.provisioningState=='Failed'].id" -o tsv | while read -r id; do
      echo "Deleting failed resource: $id"
      az resource delete --ids "$id"
    done
    echo "✅ Deprovisioned (failed) resources in '$RG' cleaned up."

    echo "🔌 Cleaning up orphaned network interfaces in '$RG'..."
    az network nic list --resource-group "$RG" --query "[].id" -o tsv | while read -r nic_id; do
      echo "Deleting NIC: $nic_id"
      az network nic delete --ids "$nic_id"
    done

    echo "🌐 Cleaning up public IPs in '$RG'..."
    az network public-ip list --resource-group "$RG" --query "[].id" -o tsv | while read -r pip_id; do
      echo "Deleting Public IP: $pip_id"
      az network public-ip delete --ids "$pip_id"
    done

    echo "📶 Cleaning up virtual networks in '$RG'..."
    az network vnet list --resource-group "$RG" --query "[].id" -o tsv | while read -r vnet_id; do
      echo "Deleting VNet: $vnet_id"
      az network vnet delete --ids "$vnet_id"
    done

    echo "💾 Cleaning up storage accounts in '$RG'..."
    az storage account list --resource-group "$RG" --query "[].id" -o tsv | while read -r sa_id; do
      echo "Deleting Storage Account: $sa_id"
      az storage account delete --ids "$sa_id" --yes
    done
  else
    echo "❌ Skipped deletion of '$RG'."
  fi
done
echo "🎉 All VMs and infrastructure deployed successfully."