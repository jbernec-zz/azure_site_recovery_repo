# AzureSiteRecovery
PowerShell Function to automate Azure Site Recovery deployment workflows for Hyper-V VMs to Azure in a non-VMM environment.

Steps to Testing the New-HyperVASRDeploymentv2.ps1 ASR deployment function.

1) Run the Remove-OrphanedVMReplication.ps1 to disable existing VM replication settings on the protected VM(s).
2) Run the Unregister-HypervHost.ps1 function to unregister the current Hyper-V host and remove local settings.
3) Run the "Get-WmiObject -Class win32_product -Filter "Name like '%recovery%'" | %{$_.Uninstall()}" script to uninstall the
a) Microsoft Azure Site Recovery Provider and b) Microsoft Azure Recovery Services Agent components.
4) Run the New-HyperVASRDeploymentv2.ps1 function. The function will provision a RG within a defined subscription. The function will call the Install-ASRProvider.psm1 module, which extracts the existing ".\AzureSiteRecoveryProvider.exe" and installs the ASR provider and Recovery services agent on the local Hyper-V host.

Prerequisites:
1) The Install-ASRProvider.psm1 module can be downloaded from my <a href="https://github.com/jbernec/AzureSiteRecovery/blob/master/Install-ASRProvider.psm1" rel="noopener" target="_blank">GitHub repository</a>. It must be copied to the PowerShell modules folder on the local host machine.
2) Download the ".\AzureSiteRecoveryProvider.exe" file from "<a href="https://aka.ms/downloaddra" rel="noopener" target="_blank">https://aka.ms/downloaddra</a>"(Microsoft could change this link at anytime) and copy the file to a local folder on the Hyper-V host that matches the $Path variable value in the Install-ASRProvider.psm1 module.
3) Ensure internet access is available on the Hyper-V Host.
