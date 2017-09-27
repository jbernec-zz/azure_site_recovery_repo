Function Install-ASRProvider{
<#
.SYNOPSIS
PowerShell Function to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.
.DESCRIPTION
PowerShell Function to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.
This function was tested using a WS2016 Virtual Machine configured as a Hyper-V Host using Nested Virtualization.
https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-deploy-with-powershell-resource-manager
.PARAMETER Vault
Vault Object.

.PARAMETER Path
File Path .

.PARAMETER SiteName
SiteName.

.PARAMETER ServerFriendlyName
ServerFriendlyName.

.PARAMETER SiteIdentifier
SiteIdentifier.

.FUNCTIONALITY
        PowerShell Language
/#>
Param(
    [System.Object]$Vault,
    [String]$SiteName,
    [String]$ServerFriendlyName,
    [String]$SiteIdentifier
    )
    
[string]$ScriptPath = Split-Path (get-variable myinvocation -scope script).value.Mycommand.Definition -Parent
#Download credential file
$Path = "C:\ARS\" 
$CredsFile = Get-AzureRmRecoveryServicesVaultSettingsFile -Vault $Vault -SiteIdentifier $SiteIdentifier -SiteFriendlyName $SiteName -Path $Path
$CredsFile.FilePath

#region extract the ASR Provider files, Install the ASR provider and Recovery Vaullt Agent and verify the Server Registration
#Extract Provider files
Set-Location -Path $Path
Start-Process -FilePath (".\AzureSiteRecoveryProvider.exe") -ArgumentList "/x:. /q" -Wait

#Install ASR Provider
C:\ARS\SETUPDR.EXE /i

#Register the Hyper-V host in the vault
$RegisterPath =  "C:\Program Files\Microsoft Azure Site Recovery Provider\"
Set-Location -Path $RegisterPath
Start-Process (".\DRConfigurator.exe") -ArgumentList "/r /friendlyname $ServerFriendlyName /Credentials $($CredsFile.FilePath)"
Set-Location -Path "\"
    }