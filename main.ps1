# Main file for running sub script

# define variables for all project
& "$PSScriptRoot/Define_var.ps1"

# Setup structure RG, Vnet, Storage, NSG, rules for traffic 
& "$PSScriptRoot/Setup_structure.ps1"