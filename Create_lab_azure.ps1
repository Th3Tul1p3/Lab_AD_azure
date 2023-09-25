# Create VM
$vm1Image = "Win2022Datacenter"
$vm1User = "lcladmin"
$vm1Pass = $vmPass
$vm1Size = "Standard_B2ms"
$vm1DiskGuid = [guid]::NewGuid().ToString().Replace("-","").Substring(0,10)
az vm create -n $vm1Name -g $rgName --image $vm1Image --admin-username $vm1User --admin-password $vm1Pass --computer-name $vm1Name --size $vm1Size --vnet-name $vnetName --subnet $subnet1Name --private-ip-address $vm1IPAddress --storage-account $storageName --use-unmanaged-disk --os-disk-name "$($vm1Name)-OSdisk-$($vm1DiskGuid)" --nsg '""' --public-ip-address '""'

$vm2Image = "Win2022Datacenter"
$vm2User = "lcladmin"
$vm2Pass = $vmPass
$vm2Size = "Standard_B2ms"
az vm create -n $vm2Name -g $rgName --image $vm2Image --admin-username $vm2User --admin-password $vm2Pass --computer-name $vm2Name --size $vm2Size --vnet-name $vnetName --subnet $subnet2Name --private-ip-address $vm2IPAddress --nsg '""' --public-ip-address '""'

$vm3Image = "Win2022Datacenter"
$vm3User = "lcladmin"
$vm3Pass = $vmPass
$vm3Size = "Standard_B2ms"
az vm create -n $vm1Name -g $rgName --image $vm3Image --admin-username $vm3User --admin-password $vm3Pass --computer-name $vm3Name --size $vm3Size --vnet-name $vnetName --subnet $subnet2Name --private-ip-address $vm3IPAddress --nsg '""' --public-ip-address '""'

# Attach data disk
$disk1Guid = [guid]::NewGuid().ToString().Replace("-","").Substring(0,10)
$disk1Name = "$($vm1Name)-DataDisk-$($disk1Guid)"
$disk1Size = "64"
$disk1Cache = "None"
az vm unmanaged-disk attach -g $rgName --vm-name $vm1Name --new --name $disk1Name --size-gb $disk1Size --caching $disk1Cache
