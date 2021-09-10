function Get-VMDiskEncryptionStatus {
    <#
    .SYNOPSIS
        Retrieve disk encryption status for all VMs.
    #>
    [CmdletBinding()]
    param (
        [string]
        $SubscriptionName,

        [int]
        $DaysOlderThan = 45    
    )

    $Subscriptions = if ($SubscriptionName) {
        (Get-AzSubscription -SubscriptionName $SubscriptionName).Name
    }
    else {
        (Get-AzSubscription).Name
    }

    foreach ($Subscription in $Subscriptions) {

        Select-AzSubscription -SubscriptionName $Subscription | Out-Null

        $VMs = Get-AzVM

        foreach ($VM in $VMs) {

            $Status = Get-AzVMDiskEncryptionStatus -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name
            
            [PSCustomObject]@{
                Subscription         = $Subscription
                ResourceGroupName    = $VM.ResourceGroupName
                Name                 = $VM.Name
                OSVolumeEncrypted    = $Status.OSVolumeEncrypted
                DataVolumesEncrypted = $Status.DataVolumesEncrypted
            }
        }
    }
}