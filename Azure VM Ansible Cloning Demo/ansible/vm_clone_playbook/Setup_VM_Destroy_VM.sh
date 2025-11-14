#!/bin/bash

echo "Choose an option:"
echo "1) Dry run (preview only)"
echo "2) Real run (create resources)"
echo "3) Destroy all resources"
read -p "Enter choice [1, 2 or 3]: " choice

# Easy variables
subscription="<AZURE_SUBSCRIPTION_ID>"   # replace with your subscription ID or set via environment
location="<AZURE_LOCATION>"            # e.g. 'eastus'
resource_group="<AZURE_RESOURCE_GROUP>" # e.g. 'MyResourceGroup'
vnet1="<VNET_NAME>"
subnet1="<SUBNET1_NAME>"
subnet2="<SUBNET2_NAME>"
address_prefix1="10.0.0.0/16"
subnet_prefix1="10.0.0.0/24"
subnet_prefix2="10.0.1.0/24"
dns_servers="8.8.8.8 8.8.4.4"
storage_account="<STORAGE_ACCOUNT>"
vm_size="Standard_B1s"
#vm_names=("<VM_NAME_A>" "<VM_NAME_B>" "<OTHER_VM>")
vm_names=("<VM_NAME_1>" "<VM_NAME_2>")

# disk_size_gb is no longer used

image="Ubuntu2204"

# Set subscription (uses placeholder variable)
az account set --subscription "$subscription"

# 🔴 Destruction logic
if [[ "$choice" == "3" ]]; then
  echo "🔴 DESTROYING infrastructure in resource group: $resource_group"
  echo "This will delete all VMs, NICs, public IPs, data disks, the storage account, the VNet, and the resource group."

  for vm in "${vm_names[@]}"; do
    vm_lower=$(echo "$vm" | tr '[:upper:]' '[:lower:]')

    az vm delete --resource-group "$resource_group" --name "$vm" --yes

    for nic in $(az network nic list --resource-group "$resource_group" --query "[?starts_with(name, '$vm_lower-nic')].name" -o tsv); do
      az network nic delete --resource-group "$resource_group" --name "$nic"
    done

    for disk in $(az disk list --resource-group "$resource_group" --query "[?starts_with(name, '$vm_lower-data')].name" -o tsv); do
      az disk delete --resource-group "$resource_group" --name "$disk" --yes
    done
  done

  az storage account delete --name "$storage_account" --resource-group "$resource_group" --yes
  az network vnet delete --resource-group "$resource_group" --name "$vnet1"

  echo "✅ Destroy request submitted. Exiting."
  exit 0
elif [[ "$choice" == "2" ]]; then
  dry_run=false
else
  dry_run=true
fi

# ✅ Resource group creation
az group create --name "$resource_group" --location "$location"

# ✅ VNet with both subnets
az network vnet create --resource-group "$resource_group" \
  --name "$vnet1" --address-prefix "$address_prefix1" \
  --subnet-name "$subnet1" --subnet-prefix "$subnet_prefix1" \
  --dns-servers $dns_servers

az network vnet subnet create --resource-group "$resource_group" \
  --vnet-name "$vnet1" --name "$subnet2" \
  --address-prefix "$subnet_prefix2"

# ✅ Storage account
az storage account create --name "$storage_account" \
  --resource-group "$resource_group" --location "$location" \
  --sku Standard_LRS

# ✅ Loop through VMs
for vm in "${vm_names[@]}"; do
  vm_lower=$(echo "$vm" | tr '[:upper:]' '[:lower:]')

  nic_list=""
  nic_count=$(( (RANDOM % 2) + 1 ))

  for i in $(seq 1 $nic_count); do
    nic_name="${vm_lower}-nic${i}"

    if $dry_run; then
      echo "[DRY RUN] az network nic create --resource-group \"$resource_group\" --name \"$nic_name\" --vnet-name \"$vnet1\" --subnet \"$subnet1\" --location \"$location\" --public-ip-address \"\""
    else
      az network nic create --resource-group "$resource_group" \
        --name "$nic_name" --vnet-name "$vnet1" --subnet "$subnet1" \
        --location "$location" --public-ip-address ""
    fi

    nic_list="$nic_list $nic_name"
  done

  os_disk_size_gb=$(( (RANDOM % 46) + 30 ))  # Random size between 30–75 GB

  if $dry_run; then
    echo "[DRY RUN] az vm create --resource-group \"$resource_group\" --name \"$vm\" --image \"$image\" --admin-username \"azureuser\" --generate-ssh-keys --nics $nic_list --size \"$vm_size\" --location \"$location\" --os-disk-size-gb $os_disk_size_gb"
  else
    az vm create \
      --resource-group "$resource_group" \
      --name "$vm" \
      --image "$image" \
      --admin-username "azureuser" \
      --generate-ssh-keys \
      --nics $nic_list \
      --size "$vm_size" \
      --location "$location" \
      --os-disk-size-gb "$os_disk_size_gb"
  fi

  disk_count=$(( (RANDOM % 2) + 1 ))
  for i in $(seq 1 $disk_count); do
    disk_name="${vm_lower}-data$i"
    disk_size_gb=$(( (RANDOM % 46) + 30 ))  # Random size between 30–75 GB
    if $dry_run; then
      echo "[DRY RUN] az vm disk attach --resource-group \"$resource_group\" --vm-name \"$vm\" --name \"$disk_name\" --new --size-gb \"$disk_size_gb\" --lun $i"
    else
      az vm disk attach --resource-group "$resource_group" --vm-name "$vm" \
        --name "$disk_name" --new --size-gb "$disk_size_gb" --lun $i
    fi
  done
done