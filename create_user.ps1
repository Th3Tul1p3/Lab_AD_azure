$scriptADC01_2 = @"
try{
  Import-Module ActiveDirectory -ErrorAction Stop
}catch{
  throw ""Module ActiveDirectory not installed""
}

`$password = ConvertTo-SecureString '$vm2Pass' -AsPlainText -Force
`$adminCred = New-Object System.Management.Automation.PSCredential -ArgumentList (""$dcA1Domain\$vm1User"", `$password)

Enable-ADOptionalFeature -Identity ""CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$dcA1DomainDN"" -Scope ForestOrConfigurationSet -Target ""$dcA2Domain"" -Confirm:`$false -Credential `$adminCred

if ((Get-ADForest).UPNsuffixes -notcontains ""$dcA2UPNSuffix""){
  `$password = ConvertTo-SecureString '$vm1Pass' -AsPlainText -Force
  `$adminCred = New-Object System.Management.Automation.PSCredential -ArgumentList (""$dcA1Domain\$vm1User"", `$password)
  Get-ADForest | Set-ADForest -UPNSuffixes @{add=""$dcA2UPNSuffix""} -Credential `$adminCred
}

function New-ADOU {
  # http://www.alexandreviot.net/2015/04/27/active-directory-create-ou-using-powershell
  param([parameter(Mandatory=`$true)] [array]`$ouList)
  ForEach(`$OU in `$ouList){
    try{
      New-ADOrganizationalUnit -Name ""`$(`$OU.Name)"" -Path ""`$(`$OU.Path)""
    }catch{
       Write-Host `$error[0].Exception.Message
    }
  }
}
`$ouCSV = ""Name;Path
S_SERVERS;$dcA2DomainDN
S_USERS;$dcA2DomainDN
ServiceAccounts;ou=S_USERS,$dcA2DomainDN
Staff;ou=S_USERS,$dcA2DomainDN
S_WORKSTATIONS;$dcA2DomainDN
S_GROUPS;$dcA2DomainDN""
`$ouList = `$ouCSV | ConvertFrom-CSV -Delimiter "";""

New-ADOU `$ouList
New-ADGroup -Name ""Grp_AllStaff"" -SamAccountName Grp_AllStaff -GroupCategory Security -GroupScope Global -DisplayName ""Grp_All Staff"" -Path ""OU=S_GROUPS,$dcA2DomainDN""

"@

az vm run-command invoke --command-id RunPowerShellScript --name $vm2Name -g $rgName --scripts $scriptADC01_2