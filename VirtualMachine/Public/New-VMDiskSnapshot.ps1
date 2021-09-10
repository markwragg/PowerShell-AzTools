function New-VMDiskSnapshot {
    <#
    .SYNOPSIS
        Creates disk snapshots for each disk of each VM or for a specified VM or VM/s (by partial name match).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The name or partial name of the VM/VMs to snapshot.
        [string]
        $VMName
    )

    $VMs = if ($VMName) { 
        Get-AzVM -Name "*$VMName*"
    }
    else {
        Get-AzVM
    }

    foreach ($VM in $VMs) {

        $OSDisk = $VM.StorageProfile.osdisk
        $DataDisks = $VM.StorageProfile.dataDisks
        
        $Disks = @($OSDisk) + @($DataDisks)

        foreach ($Disk in $Disks) {

            $SnapshotDate = Get-Date -Format 'dd-MMMM-yyyy'
            $SnapshotName = "$($Disk.Name)-$SnapshotDate"
            
            if ($PSCmdlet.ShouldProcess($SnapshotName, 'New-AzSnapshot')) {

                $SnapshotParams = @{
                    SourceUri    = $Disk.ManagedDisk.Id
                    Location     = $VM.Location 
                    CreateOption = 'copy'
                    SkuName      = 'Standard_ZRS'
                }

                $Snapshot = New-AzSnapshotConfig @SnapshotParams

                Write-Host "Creating $SnapshotName.."
                New-AzSnapshot -ResourceGroupName $VM.ResourceGroupName -SnapshotName $SnapshotName -Snapshot $Snapshot
            }
        }
    }
}