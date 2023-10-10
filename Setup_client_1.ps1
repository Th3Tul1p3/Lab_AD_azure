az network nsg create -n $nsg2Name -g $rgName
az network vnet subnet update -g $rgName -n $subnet2Name --vnet-name $vnetName --network-security-group $nsg2Name
az network nsg rule create --nsg-name $nsg2Name -g $rgName -n "Allow_RDP" --priority 100 --access "allow" --destination-address-prefixes $subnet1Range --destination-port-ranges "3389" --protocol "TCP" --description "Allow RDP"
az network nsg rule create --nsg-name $nsg2Name -g $rgName -n "Allow_AD_TCP" --priority 110 --access "allow" --source-address-prefixes $subnet1Range $subnet2Range  --destination-address-prefixes $subnet1Range --destination-port-ranges 135 389 636 53 88 445 49152-65535 --protocol "TCP" --description "Allow AD traffic TCP"
az network nsg rule create --nsg-name $nsg2Name -g $rgName -n "Allow_AD_UDP" --priority 111 --access "allow" --source-address-prefixes $subnet1Range $subnet2Range  --destination-address-prefixes $subnet1Range --destination-port-ranges 53 88 389 --protocol "UDP" --description "Allow AD traffic UDP"
az network nsg rule create --nsg-name $nsg2Name -g $rgName -n "Deny_Inbound" --priority 4000 --access "deny" --source-address-prefixes "*" --destination-address-prefixes $subnet1Range --destination-port-ranges "*" --protocol "*" --description "Deny inbound traffic"
  
az vm create -n $vm2Name -g $rgName --image $vm2Image --admin-username $vm2User --admin-password $vm2Pass --computer-name $vm2Name --size $vm2Size --vnet-name $vnetName --subnet $subnet2Name --private-ip-address $vm2IPAddress --nsg '""' --public-ip-address '""'

$scriptACLIENT01_1 = @"
Set-TimeZone -id 'W. Europe Standard Time'
`$IP = ""$vm5IPAddress""
`$MaskBits = 24
`$Gateway = ""$($vm5IPAddress -split "\d{1,3}$" -join "1")""
`$DNS = ""$vm2IPAddress""
`$IPType = ""IPv4""
`$adapter = Get-NetAdapter | ? {`$_.Status -eq ""up""}
`$interface = `$adapter | Get-NetIPInterface -AddressFamily `$IPType
If (`$interface.Dhcp -eq ""Enabled"") {
  Get-NetAdapterBinding -ComponentID ms_tcpip6 | Disable-NetAdapterBinding
  If ((`$adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    `$adapter | Remove-NetIPAddress -AddressFamily `$IPType -Confirm:`$false
  }
  If ((`$adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    `$adapter | Remove-NetRoute -AddressFamily `$IPType -Confirm:`$false
  }
  `$adapter | New-NetIPAddress -AddressFamily `$IPType -IPAddress `$IP -PrefixLength `$MaskBits -DefaultGateway `$Gateway
  `$adapter | Set-DnsClientServerAddress -ServerAddresses `$DNS
}
Start-Sleep -Seconds 15 # Wait for DNS changes

Add-Computer -DomainName ""$dcA1Domain"" -Credential (New-Object System.Management.Automation.PSCredential(""$dcA1Domain\$vm5User"",(ConvertTo-SecureString '$vm5Pass' -AsPlainText -Force))) -OUPath ""OU=S_WORKSTATIONS,$dcA2DomainDN"" -Restart
"@

az vm run-command invoke --command-id RunPowerShellScript --name $vm5Name -g $rgName --scripts $scriptACLIENT01_1