Function Install-ASRProvider{
<#
.SYNOPSIS
PowerShell module to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.
.DESCRIPTION
PowerShell module to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.
This function was tested using a WS2016 Virtual Machine configured as a Hyper-V Host using Nested Virtualization.
https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-deploy-with-powershell-resource-manager
The Install-ASRProvider.psm1 module downloads the ".\AzureSiteRecoveryProvider.exe" file from "https://aka.ms/downloaddra"(Microsoft could change this link at anytime) 
to a local folder on the Hyper-V host that matches the $Path variable value in the Install-ASRProvider.psm1 module.

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
#Download  site recovery provider file and credential file
Invoke-WebRequest -Uri "https://aka.ms/downloaddra" -OutFile "c:\ars\AzureSiteRecoveryProvider.exe"
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