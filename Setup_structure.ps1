# create RG
az group create -l $region -n $rgName

# create vnet and subnet stuff
az network vnet create -g $rgName -n $vnetName --address-prefix $vnetRange --subnet-name $subnet1Name --subnet-prefixes $subnet1Range
az network vnet subnet create -g $rgName --vnet-name $vnetName -n $subnet2Name --address-prefixes $subnet2Range


# create storage 
az storage account create -n $storageName -g $rgName --sku $storageSku --kind $storageKind

# Create NSG - A-DC
az network nsg create -n $nsg1Name -g $rgName

# Add rules to NSG to allow AD traffic
az network vnet subnet update -g $rgName -n $subnet1Name --vnet-name $vnetName --network-security-group $nsg1Name
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Allow_RDP" --priority 100 --access "allow" --destination-address-prefixes $subnet1Range --destination-port-ranges "3389" --protocol "TCP" --description "Allow RDP"
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Allow_AD_TCP" --priority 110 --access "allow" --source-address-prefixes $subnet1Range $subnet2Range  --destination-address-prefixes $subnet1Range --destination-port-ranges 135 389 636 53 88 445 49152-65535 --protocol "TCP" --description "Allow AD traffic TCP"
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Allow_AD_UDP" --priority 111 --access "allow" --source-address-prefixes $subnet1Range $subnet2Range  --destination-address-prefixes $subnet1Range --destination-port-ranges 53 88 389 --protocol "UDP" --description "Allow AD traffic UDP"
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Deny_Inbound" --priority 4000 --access "deny" --source-address-prefixes "*" --destination-address-prefixes $subnet1Range --destination-port-ranges "*" --protocol "*" --description "Deny inbound traffic"

az network vnet subnet update -g $rgName -n $subnet1Name --vnet-name $vnetName --network-security-group $nsg1Name