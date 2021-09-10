function Get-DiskEncryptionStatus {
    <#
    .SYNOPSIS
        Retrieve disk encryption status for all disks.
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

        $Disks = Get-AzDisk

        foreach ($Disk in $Disks) {
            [PSCustomObject]@{
                Subscription      = $Subscription
                ResourceGroupName = $Disk.ResourceGroupName
                Name              = $Disk.Name
                EncryptionEnabled = $Disk.EncryptionSettingsCollection.Enabled
                DiskSizeGB        = $Disk.DiskSizeGB
            }
        }
    }
}