function Get-OldDiskSnapshot {
    <#
    .SYNOPSIS
        Retrieve disk snapshots older than the specified number of days.
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

    $AllSnapshots = foreach ($Subscription in $Subscriptions) {

        Select-AzSubscription -SubscriptionName $Subscription | Out-Null

        $Snapshots = Get-AzSnapshot | Where-Object { $_.TimeCreated -le (Get-Date).AddDays(-$DaysOlderThan) } | Sort-Object TimeCreated

        foreach ($Snapshot in $Snapshots) {
            [PSCustomObject]@{
                Subscription      = $Subscription
                ResourceGroupName = $Snapshot.ResourceGroupName
                Name              = $Snapshot.Name
                TimeCreated       = $Snapshot.TimeCreated
                DiskSizeGB        = $Snapshot.DiskSizeGB
                AgeInDays         = ((Get-Date) - $Snapshot.TimeCreated).Days
            }
        }
    }

    $AllSnapshots | Sort-Object TimeCreated
}