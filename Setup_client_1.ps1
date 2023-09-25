$nsg3Name = "jr-trustlab-nsg-a-app"

az network nsg create -n $nsg3Name -g $rgName
az network vnet subnet update -g $rgName -n $subnet2Name --vnet-name $vnetName --network-security-group $nsg3Name
az network nsg rule create --nsg-name $nsg3Name -g $rgName -n "Allow_RDP" --priority 100 --access "allow" --source-address-prefixes $subnet99Range --destination-address-prefixes $subnet2Range --destination-port-ranges "3389" --protocol "TCP" --description "Allow RDP from Bastion"
az network nsg rule create --nsg-name $nsg3Name -g $rgName -n "Allow_HTTP" --priority 110 --access "allow" --source-address-prefixes $subnet1Range $subnet2Range $subnet3Range --destination-address-prefixes $subnet2Range --destination-port-ranges 80 443 --protocol "TCP" --description "Allow HTTP traffic"
az network nsg rule create --nsg-name $nsg3Name -g $rgName -n "Deny_Inbound" --priority 4000 --access "deny" --source-address-prefixes "*" --destination-address-prefixes $subnet2Range --destination-port-ranges "*" --protocol "*" --description "Deny inbound traffic"

$logWsName = "jr-trustlab-logs"
$flow2LogName = "jr-trustlab-flow-a-app"
az network watcher flow-log create -n $flow2LogName -g $rgName --enabled true --nsg $nsg3Name --storage-account $storageName --location $region --format JSON --log-version 2 --retention 7 --traffic-analytics --workspace $logWsName