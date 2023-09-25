$region = "EastUS"
$rgName = "Lab-AD-rg"
$rgwatcher = "NetworkWatcherRG"

$vnetName = "Lab-AD-vnet-01"
$vnetRange = "10.1.0.0/16"
$vm1IPAddress = "10.1.10.10"
$vm2IPAddress = "10.1.30.30"
$vm3IPAddress = "10.1.30.31"
$subnet1Name = "domain-ad"
$subnet1Range = "10.1.10.0/24"
$subnet2Name = "client"
$vm1Name = "vm-a-dc01"
$vm2Name = "vm-client-1"
$vm3Name = "vm-client-2"
$subnet2Range = "10.1.30.0/24"

$nsg1Name = "Lab-AD-nsg-a-ad"
$vmPass = '3GzUTdBU84Wn#ksL2y7Kw*sY'
$userPass = '$vmPass'

# generate name for storage 
$TokenSet = @{
        L = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        N = [Char[]]'0123456789'
    }
$Lower = Get-Random -Count 12 -InputObject $TokenSet.L
$Number = Get-Random -Count 5 -InputObject $TokenSet.N
$StringSet =  $Lower + $Number 
$storageName = (Get-Random -Count 20 -InputObject $StringSet) -join '' # must be in lower case 
$storageSku = "Standard_LRS"
$storageKind = "StorageV2"

# create RG
az group create -l $region -n $rgName

# create vnet and subnet stuff
az network vnet create -g $rgName -n $vnetName --address-prefix $vnetRange --subnet-name $subnet1Name --subnet-prefixes $subnet1Range
az network vnet subnet create -g $rgName --vnet-name $vnetName -n $subnet2Name --address-prefixes $subnet2Range

# create storage 
az storage account create -n $storageName -g $rgName --sku $storageSku --kind $storageKind