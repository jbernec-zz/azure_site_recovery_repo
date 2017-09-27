# AzureSiteRecovery
PowerShell Function to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.

Steps to Testing the New-HyperVASRDeploymentv2.ps1 ASR deployment function.

Run the Remove-OrphanedVMReplication.ps1 to disable existing VM replication settings on the protected VM(s).
Run the Unregister-HypervHost.ps1 function to unregister the current Hyper-V host and remove local settings.
Run the "Get-WmiObject -Class win32_product -Filter "Name like '%recovery%'" | %{$_.Uninstall()}" script to uninstall the
a) Microsoft Azure Site Recovery Provider and b) Microsoft Azure Recovery Services Agent components.
Run the New-HyperVASRDeploymentv2.ps1 function. The function will provision a RG within a defined subscription. The function will call the Install-ASRProvider.psm1 module, which extracts the existing ".\AzureSiteRecoveryProvider.exe" and installs the ASR provider and Recovery services agent on the local Hyper-V host.

Prerequisites:
Ensure that the Install-ASRProvider.psm1 module is present on the local host machine.
Copy the ".\AzureSiteRecoveryProvider.exe"
file to a local folder on the Hyper-V host that matches the $Path variable value in the Install-ASRProvider.psm1 module.
Ensure internet access is available on the Hyper-V.
