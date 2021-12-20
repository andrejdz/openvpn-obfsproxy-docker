#!/bin/bash

set -e

# Essential variables
location='westeurope'
suffix="weu"
subscriptionId='ff91e769-81ed-4f71-aa71-806e47e7b19d'
resourceGroupName="openvpn-rg-$suffix"

# Virtual network variables
vnetName="openvpn-vnet-$suffix"
subnetName="openvpn-subnet-$suffix"
addressPrefix='10.0.0.0/24'

# Network security group variables
nsgName="openvpn-nsg-$suffix"
myIp='134.17.0.0/16'
protocol='Tcp'

# Virual machine variables
vmName="openvpn-vm-$suffix"
nicName="openvpn-vm-nic-$suffix"
publicIpName="openvpn-vm-publicip-$suffix"
vmSize='Standard_B1ms'
storageSku='Premium_LRS'
osDiskName="openvpn-vm-osdisk-$suffix"
vmImage='Canonical:UbuntuServer:18.04-LTS:latest'
userName='openvpn'
homeFolder="/home/$userName"
# Path to the docker installer script
dockerInstallerScriptPath="$homeFolder/openvpn-eu/create-infrastructure/install-docker.sh"
# Path to ssh folder on deployment machine
sshFolderPath="$homeFolder/.ssh"
privateKeyName="id_rsa_openvpn-$suffix"
publicKeyName="id_rsa_openvpn-$suffix.pub"

echo 'Generating ssh key.'
mkdir -p $sshFolderPath
rm -f "$sshFolderPath/$privateKeyName"
rm -f "$sshFolderPath/$publicKeyName"
ssh-keygen \
    -t 'rsa' \
    -b 4096 \
    -C "$userName@$vmName" \
    -f "$sshFolderPath/$privateKeyName" \
    -N '' \
    -q

az login

echo "Setting defaults."
az account set --subscription $subscriptionId
az configure --defaults group=$resourceGroupName
az configure --defaults location=$location
az configure --defaults vm=$vmName

echo "Creating new resource group: $resourceGroupName."
az group create --location $location \
                --name $resourceGroupName

echo "Creating network security group: $nsgName."
az network nsg create --name $nsgName

echo "Creating security rules."
az network nsg rule create \
    --name 'SSH' \
    --nsg-name $nsgName \
    --priority 100 \
    --access 'Allow' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 22 \
    --direction 'Inbound' \
    --protocol 'Tcp' \
    --source-address-prefixes $myIp \
    --source-port-ranges '*'

az network nsg rule create \
    --name 'OpenVPN' \
    --nsg-name $nsgName \
    --priority 110 \
    --access 'Allow' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 943 \
    --direction 'Inbound' \
    --protocol 'Tcp' \
    --source-address-prefixes $myIp \
    --source-port-ranges '*'

az network nsg rule create \
    --name 'HTTPS' \
    --nsg-name $nsgName \
    --priority 120 \
    --access 'Allow' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 443 \
    --direction 'Inbound' \
    --protocol 'Tcp' \
    --source-address-prefixes $myIp \
    --source-port-ranges '*'

az network nsg rule create \
    --name 'Obfsproxy' \
    --nsg-name $nsgName \
    --priority 130 \
    --access 'Allow' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 21194 \
    --direction 'Inbound' \
    --protocol 'Tcp' \
    --source-address-prefixes $myIp \
    --source-port-ranges '*'

echo "Creating virtual network: $vnetName."
az network vnet create \
    --name $vnetName \
    --address-prefixes $addressPrefix \
    --network-security-group $nsgName

echo "Creating new subnet: $subnetName."
az network vnet subnet create \
    --name $subnetName \
    --vnet-name $vnetName \
    --address-prefixes $addressPrefix \
    --network-security-group $nsgName \
    --vnet-name $vnetName

echo "Creating public IP address: $publicIpName."
az network public-ip create \
    --name $publicIpName \
    --allocation-method 'Dynamic' \
    --sku 'Basic' \
    --version 'IPv4'

echo "Creating network interface: $nicName."
az network nic create \
    --name $nicName \
    --subnet $subnetName \
    --network-security-group $nsgName \
    --public-ip-address $publicIpName \
    --vnet-name $vnetName

echo "Creating virtual machine: $vmName."
az vm create \
    --name $vmName \
    --admin-username $userName \
    --authentication-type 'ssh' \
    --os-disk-name $osDiskName \
    --os-disk-caching 'ReadWrite' \
    --data-disk-caching 'ReadWrite' \
    --enable-agent true \
    --image $vmImage \
    --nics $nicName \
    --patch-mode 'Manual' \
    --size $vmSize \
    --ssh-key-values "$sshFolderPath/$publicKeyName" \
    --storage-sku $storageSku

echo "Installing docker in virtual machine."
# Custom script that should be executed during deployment
az vm run-command invoke \
    --command-id 'RunShellScript' \
    --scripts @"$dockerInstallerScriptPath" \
    --parameters $userName