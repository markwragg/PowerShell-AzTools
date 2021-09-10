function Get-VMBackupStatus {
    <#
    .SYNOPSIS
        Retrieve VM backup status for all VMs.
    #>
    [CmdletBinding()]
    param (
        [string]
        $SubscriptionName
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
        $BackupVaults = Get-AzRecoveryServicesVault

        foreach ($VM in $VMs) {

            $BackupStatus = Get-AzRecoveryServicesBackupStatus -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Type 'AzureVM'
            
            $Backup = if ($BackupStatus.BackedUp -eq $true) {
                
                $BackupVault = $BackupVaults | Where-Object { $_.ID -eq $BackupStatus.VaultId }
                $Container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -VaultId $BackupVault.ID -FriendlyName $VM.Name
                
                Get-AzRecoveryServicesBackup -Container $Container -WorkloadType AzureVM -VaultId $BackupVault.ID
            }

            [PSCustomObject]@{
                Subscription              = $Subscription
                ResourceGroupName         = $VM.ResourceGroupName
                Name                      = $VM.Name
                Location                  = $VM.Location
                BackedUp                  = $BackupStatus.BackedUp
                RecoveryVaultName         = $BackupVault.Name
                RecoveryVaultPolicy       = $Backup.ProtectionPolicyName
                BackupHealthStatus        = $Backup.HealthStatus
                BackupProtectionStatus    = $Backup.ProtectionStatus
                LastBackupStatus          = $Backup.LastBackupStatus
                LastBackupTime            = $Backup.LastBackupTime
                BackupDeleteState         = $Backup.DeleteState
                BackupLatestRecoveryPoint = $Backup.LatestRecoveryPoint
            }
        }
    }
}