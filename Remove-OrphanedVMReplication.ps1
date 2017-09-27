Param (
    [parameter(Mandatory=$true)]
    $VMName
)
 $vm = Get-WmiObject -Namespace "root\virtualization\v2" -Query "Select * From Msvm_ComputerSystem Where ElementName = '$VMName'"
 $replicationService = Get-WmiObject -Namespace "root\virtualization\v2"  -Query "Select * From Msvm_ReplicationService"
 $replicationService.RemoveReplicationRelationship($vm.__PATH)