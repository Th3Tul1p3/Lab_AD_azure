# Main file for running sub script

# Setup structure RG, Vnet, Storage, NSG, rules for traffic 
& "$PSScriptRoot/Setup_structure.ps1"

# setup Vm for AD + Setup ad ds 
& "$PSScriptRoot/Setup_AD_vm.ps1"

# Setup clients, VM, join AD
