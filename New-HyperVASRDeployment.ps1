<#
.SYNOPSIS
PowerShell Function to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.
.DESCRIPTION
PowerShell Function to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.
This function was tested using a WS2016 Virtual Machine configured as a Hyper-V Host using Nested Virtualization.
https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-deploy-with-powershell-resource-manager.
Prerequisites: 
1) The Install-ASRProvider.psm1 module must be copied to the PowerShell modules folder on the local host machine.If the solution is deployed as a runbook, this module will need imported into the Automation account module folder.
2) The Install-ASRProvider.psm1 module also downloads the ".\AzureSiteRecoveryProvider.exe" file from "https://aka.ms/downloaddra"(Microsoft could change this link at anytime) to a local folder on the Hyper-V host that matches the $Path variable value in the Install-ASRProvider.psm1 module.
3) Ensure internet access is available.
4) An Azure automation account will have to be provisioned. This function was developed to run as a Runbook or locally. It authenticates to azure using an Azure RunAsAccount.
.PARAMETER SubscriptionName
Subscription name of the Recovery Vault infrastructure.
.PARAMETER Location
Location of the Recovery Vault .
.PARAMETER ResourceGroupName
ResourceGroupName to deploy the Recovery Vault infrastructure.
.PARAMETER StorageAccountName
StorageAccountName to store replicated VM vhds.
.PARAMETER ServerFriendlyName
ServerFriendlyName of the Hyper-V to be registered with the Azure Site Recovery Site.

.EXAMPLE
New-HyperVASRDeployment

.FUNCTIONALITY
    PowerShell Language
/#>

Param(
[String]$ResourceGroupName = "RGASR",
[String]$SubscriptionName = "Free Trial",
[String]$Location = "southcentralus",
[String]$ServerFriendlyName = "WS2016",
[String]$StorageAccountName = "storeasr18"
)

#region Azure Logon
try {
    # Get the connection "AzureRunAsConnection "
    $connectionName = "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
Select-AzureRmSubscription -SubscriptionName $SubscriptionName

#endregion
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.SiteRecovery
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.RecoveryServices

#Create Recovery ResourceGroup
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

#Create Storage Account.Geo-redundant storage or locally redundant storage can be used.Geo-redundant storage is recommended.
#With geo-redundant storage, data is resilient if a regional outage occurs, or if the primary region can't be recovered.
$SkuName = "Standard_LRS"
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -SkuName $SkuName -Location $Location

#Create new Recovery Services Vault
$RecoveryServicesVaultName = "RecoveryVaultDemo"
New-AzureRmRecoveryServicesVault -Name $RecoveryServicesVaultName -ResourceGroupName $ResourceGroupName -Location $Location
#Set Recovery Service Vault Context
$Vault = Get-AzureRmRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $RecoveryServicesVaultName
Set-AzureRmSiteRecoveryVaultSettings -ARSVault $Vault
Start-Sleep -Seconds 30

#Create new Hyper-V Site
$SiteName = "HypervSiteDemo"
New-AzureRmSiteRecoveryFabric -Name $SiteName -Type HyperVSite
Start-Sleep -Seconds 30
$HyperVSite = Get-AzureRmSiteRecoveryFabric -Name $SiteName

#The above cmdlet starts a site recovery job to create the site. Verify that the job completed successfully
(Get-AzureRmSiteRecoveryJob)[0]
Get-AzureRmSiteRecoveryJob -State "Succeeded"

#Generate and download a registration key for the new Hyper-V site
Install-ASRProvider -Vault $Vault -SiteName $SiteName -ServerFriendlyName $ServerFriendlyName -SiteIdentifier $HyperVSite.SiteIdentifier
Start-Sleep -Seconds 60
#Verify the registration completed successfully
Get-AzureRmSiteRecoveryServicesProvider -FriendlyName $ServerFriendlyName -Fabric (Get-AzureRmSiteRecoveryFabric -Name $HyperVSite.FriendlyName)

#Create a replcation policy and map it to a Protection container
$ReplicationFrequencyInSeconds = 300
$PolicyName = "ReplicaPolicy"
$RecoveryPoints = 3
$StorageAccountId = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Id
New-AzureRmSiteRecoveryPolicy -Name $PolicyName -ReplicationProvider HyperVReplicaAzure -ReplicationFrequencyInSeconds $ReplicationFrequencyInSeconds `
-RecoveryPoints $RecoveryPoints -ApplicationConsistentSnapshotFrequencyInHours 1 -RecoveryAzureStorageAccountId $StorageAccountId
Start-Sleep -Seconds 30

#Get the site object/container created earlier above
$Container = Get-AzureRmSiteRecoveryProtectionContainer -FriendlyName $HyperVSite.FriendlyName -Fabric (Get-AzureRmSiteRecoveryFabric)
$PolicyMappingName = "ReplicaPolicyMapping"
$PolicyObject = Get-AzureRmSiteRecoveryPolicy -Name $PolicyName
New-AzureRmSiteRecoveryProtectionContainerMapping -Name $PolicyMappingName -Policy $PolicyObject -PrimaryProtectionContainer $Container
Start-Sleep -Seconds 180

#Verify the Mapping status
$ProtectionContainerMapping = Get-AzureRmSiteRecoveryProtectionContainerMapping -Name $PolicyMappingName -ProtectionContainer $Container

#Get and display Site Recovery Protectable Items for the specified Container
$ReplicationProtectableItem = Get-AzureRmSiteRecoveryProtectableItem -ProtectionContainer $Container
#Configure Protection for specific VMs or Items and initiate DR replication
$ProtectableItem = New-AzureRmSiteRecoveryReplicationProtectedItem -ProtectableItem $ReplicationProtectableItem -Name $ReplicationProtectableItem.FriendlyName -ProtectionContainerMapping $ProtectionContainerMapping `
-RecoveryAzureStorageAccountId $StorageAccountId -OSDiskName $ReplicationProtectableItem.Disks[0].Name -OS Windows -Verbose

#Check the status of the DR replication job
Get-AzureRmSiteRecoveryJob -Job $ProtectableItem