# Create VM
$vm1Image = "Win2022Datacenter"
$vm1User = "lcladmin"
$vm1Pass = $vmPass
$vm1Size = "Standard_B2ms"
az vm create -n $vm1Name -g $rgName --image $vm1Image --admin-username $vm1User --admin-password $vm1Pass --computer-name $vm1Name --size $vm1Size --vnet-name $vnetName --subnet $subnet1Name --private-ip-address $vm1IPAddress --nsg '""' --public-ip-address '""'

$vm2Image = "Win2022Datacenter"
$vm2User = "lcladmin"
$vm2Pass = $vmPass
$vm2Size = "Standard_B2ms"
az vm create -n $vm2Name -g $rgName --image $vm2Image --admin-username $vm2User --admin-password $vm2Pass --computer-name $vm2Name --size $vm2Size --vnet-name $vnetName --subnet $subnet2Name --private-ip-address $vm2IPAddress --nsg '""' --public-ip-address '""'

