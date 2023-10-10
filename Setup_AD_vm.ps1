# Create NSG - A-DC
az network nsg create -n $nsg1Name -g $rgName

# Add rules to NSG to allow AD traffic
az network vnet subnet update -g $rgName -n $subnet1Name --vnet-name $vnetName --network-security-group $nsg1Name
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Allow_RDP" --priority 100 --access "allow" --destination-address-prefixes $subnet1Range --destination-port-ranges "3389" --protocol "TCP" --description "Allow RDP"
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Allow_AD_TCP" --priority 110 --access "allow" --source-address-prefixes $subnet1Range $subnet2Range  --destination-address-prefixes $subnet1Range --destination-port-ranges 135 389 636 53 88 445 49152-65535 --protocol "TCP" --description "Allow AD traffic TCP"
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Allow_AD_UDP" --priority 111 --access "allow" --source-address-prefixes $subnet1Range $subnet2Range  --destination-address-prefixes $subnet1Range --destination-port-ranges 53 88 389 --protocol "UDP" --description "Allow AD traffic UDP"
az network nsg rule create --nsg-name $nsg1Name -g $rgName -n "Deny_Inbound" --priority 4000 --access "deny" --source-address-prefixes "*" --destination-address-prefixes $subnet1Range --destination-port-ranges "*" --protocol "*" --description "Deny inbound traffic"

az network vnet subnet update -g $rgName -n $subnet1Name --vnet-name $vnetName --network-security-group $nsg1Name

# Create VM
az vm create -n $vm1Name -g $rgName --image $vm1Image --admin-username $vm1User --admin-password $vm1Pass --computer-name $vm1Name --size $vm1Size --vnet-name $vnetName --subnet $subnet1Name --private-ip-address $vm1IPAddress --storage-account $storageName --use-unmanaged-disk --os-disk-name "$($vm1Name)-OSdisk-$($vm1DiskGuid)" --nsg '""' --public-ip-address '""'


# Set static IP address
# Install Active Directory Domain Services
# Install domain 'contoso.internal'
# Add public domain 'contoso.com' as UPN suffix
$dcA1Domain="corp.local"
$dcA1DomainNetbios="corp"
$scriptADC01_1 = @"
Set-TimeZone -id 'W. Europe Standard Time'
`$disks = Get-Disk | Where partitionstyle -eq 'raw'
If (`$disks) {
  `$disks | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -UseMaximumSize -DriveLetter ""G"" | Format-Volume -FileSystem NTFS -NewFileSystemLabel ""Data"" -Confirm:`$false -Force
}
`$domain = ""$dcA1Domain""
`$domainnetbios = ""$dcA1DomainNetbios""
`$IP = ""$vm1IPAddress""
`$MaskBits = 24
`$Gateway = ""$($vm1IPAddress -split "\d{1,3}$" -join "1")""
`$DNS = ""$vm1IPAddress""
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

Install-WindowsFeature AD-Domain-Services, rsat-adds -IncludeAllSubFeature
Install-ADDSForest -DomainName `$domain -SafeModeAdministratorPassword (convertto-securestring '$vm1Pass' -asplaintext -force)  -DomainMode Win2012R2 -DomainNetbiosName `$domainnetbios -ForestMode Win2012R2 -DatabasePath """G:\NTDS""" -SysvolPath """G:\SYSVOL""" -LogPath """G:\Logs""" -Force"

"@

az vm run-command invoke --command-id RunPowerShellScript --name $vm1Name -g $rgName --scripts $scriptADC01_1

$dcA2UPNSuffix = "senthorus.com"
$scriptADC01_2 = @"
try{
  Import-Module ActiveDirectory -ErrorAction Stop
}catch{
  throw ""Module ActiveDirectory not installed""
}

if ((Get-ADForest).UPNsuffixes -notcontains ""$dcA2UPNSuffix""){
  Get-ADForest | Set-ADForest -UPNSuffixes @{add=""$dcA2UPNSuffix""}
}
"@
az vm run-command invoke --command-id RunPowerShellScript --name $vm1Name -g $rgName --scripts $scriptADC01_2

$scriptADC02_3 = @"
try{
  Import-Module ActiveDirectory -ErrorAction Stop
}catch{
  throw ""Module ActiveDirectory not installed""
}

function Create-TestUsers {
  param(
    [parameter(Mandatory=`$true)] [array]`$UserList,
    [parameter(Mandatory=`$true)] [string]`$UserPass,
    [parameter(Mandatory=`$true)] [string]`$DomainSuffix,
    [parameter(Mandatory=`$true)] [string]`$OUPath
  )

  # https://365lab.net/2014/01/08/create-test-users-in-a-domain-with-powershell/
  `$departments = @(""IT"",""Finance"",""Logistics"",""Sourcing"",""Human Resources"")
  ForEach(`$user in `$userList){
    `$firstname = (Get-Culture).TextInfo.ToTitleCase(`$user.Firstname)
    `$lastname = (Get-Culture).TextInfo.ToTitleCase(`$user.Lastname)
    `$i = get-random -Minimum 0 -Maximum `$departments.count
    `$department = `$departments[`$i]
    `$username = `$firstname.Substring(0,2).tolower() + `$lastname.Substring(0,4).tolower()
    `$exit = 0
    `$count = 1
    do {
      try {
        `$userexists = Get-AdUser -Identity `$username
        `$username = `$firstname.Substring(0,2).tolower() + `$lastname.Substring(0,4).tolower() + `$count++
      } catch {
        `$exit = 1
      }
    } while (`$exit -eq 0)
    `$displayname = `$firstname + "" "" + `$lastname
    `$upn = `$username + ""@"" + `$DomainSuffix
    `$email = `$firstname + ""."" + `$lastname + ""@"" + `$DomainSuffix
    Write-Host ""Creating user `$username in `$OUPath""
    New-ADUser -Name `$displayName -DisplayName `$displayName -SamAccountName `$username -UserPrincipalName `$upn -EmailAddress `$email -GivenName `$firstname -Surname `$lastname -description ""Test User"" -Path `$OUPath -Enabled `$true -ChangePasswordAtLogon `$false -Department `$Department -AccountPassword (ConvertTo-SecureString `$userPass -AsPlainText -force)
  }
}

`$userOU = ""ou=Staff,ou=S_USERS,$dcA2DomainDN""
`$userPass = '$userPass'
`$usersCSV = ""Firstname;Lastname
barry;tycholiz
benjamin;rogers
bill;rapp
bill;williams
brad;mckay
cara;semperger
carol;stclair
chris;dorland
chris;germany
chris;stokley
cooper;richey
craig;dean
dana;davis
danny;mccarty
dan;hyvl
daren;farmer
darrell;schoolcraft
darron;cgiron
david;delainey""
`$userList = `$usersCSV | ConvertFrom-CSV -Delimiter "";""

`$users = Get-ADUser -Filter * -SearchBase `$userOU | select -expand samAccountName
If ((`$users) -eq `$null) {
  Create-TestUsers `$userList `$userPass ""$dcA2UPNSuffix"" `$userOU
}
`$users = Get-ADUser -Filter * -SearchBase `$userOU | select -expand samAccountName
`$group = ""Grp_AllStaff""
Add-ADGroupMember -Identity `$group -Members `$users

"@
az vm run-command invoke --command-id RunPowerShellScript --name $vm2Name -g $rgName --scripts $scriptADC02_3