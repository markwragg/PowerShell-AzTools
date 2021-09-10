function Remove-OldDiskSnapshot {
    <#
    .SYNOPSIS
        Removes disk snapshots older than the specified number of days (45 by default).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [int]
        $DaysOlderThan = 45  
    )

    $Snapshots = Get-AzSnapshot | Where-Object { $_.TimeCreated -le (Get-Date).AddDays(-$DaysOlderThan) } | Sort-Object TimeCreated

    foreach ($Snapshot in $Snapshots) {
            
        if ($PSCmdlet.ShouldProcess($Snapshot.Name, 'Remove-AzSnapshot')) {

            $AgeInDays = ((Get-Date) - $Snapshot.TimeCreated).Days

            Write-Host "Removing $($Snapshot.name) ($AgeInDays days old).."
            $Snapshot | Remove-AzSnapshot -Force
        }
    }
}