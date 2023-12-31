$region = "EastUS"
$rgName = "Lab-AD-rg"
$rgwatcher = "NetworkWatcherRG"

$vnetName = "Lab-AD-vnet-01"
$vnetRange = "10.1.0.0/16"
$subnet1Name = "domain-ad"
$subnet1Range = "10.1.10.0/24"
$subnet2Name = "client"
$vm1Name = "vm-a-dc01"
$vm1IPAddress = "10.1.10.10"
$vm2Name = "vm-client-1"
$vm2IPAddress = "10.1.30.30"
$vm3Name = "vm-client-2"
$vm3IPAddress = "10.1.30.3"
$subnet2Range = "10.1.30.0/24"

$nsg1Name = "Lab-AD-nsg-a-ad"
$nsg2Name = "Lab-AD-nsg-a-client"
$vmPass = '3GzUTdBU84Wn#ksL2y7Kw*sY'
$userPass = '$vmPass'

# VM AD
$vm1Image = "Win2022Datacenter"
$vm1User = "lcladmin"
$vm1Pass = $vmPass
$vm1Size = "Standard_B2ms"

# VM client 1 
$vm2Image = "Win2022Datacenter"
$vm2User = "lcladmin"
$vm2Pass = $vmPass
$vm2Size = "Standard_B2ms"

# create RG
az group create -l $region -n $rgName

# create vnet and subnet stuff
az network vnet create -g $rgName -n $vnetName --address-prefix $vnetRange --subnet-name $subnet1Name --subnet-prefixes $subnet1Range
az network vnet subnet create -g $rgName --vnet-name $vnetName -n $subnet2Name --address-prefixes $subnet2Range
