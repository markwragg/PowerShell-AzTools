function Move-StorageBlobs {
    <#
    .SYNOPSIS
        Moves Blobs from one path to another within the same storage container and/or removes blobs from the source path that already exist in the destination path.

    .EXAMPLE
        Move-StorageBlobs -StorageAccountKey AbCdEfGhIjKLmNoPqRsTuVwXyZ1234567890== -SourcePrefix 'Tlog/' -DestinationPrefix 'TLOG/'
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        # The resource group name for the storage account
        [string]
        $ResourceGroupName = 'prd-strg-ac',

        # The storage account name
        [string]
        $StorageAccountName = 'proddbbkpstore',

        # The storage account access key
        [parameter(Mandatory)]
        [string]
        $StorageAccountKey,

        # The name of the container
        [string]
        $Container = 'packagedbbackup',

        # The prefix (usually a folder name) for the files to be moved to the destination prefix. E.g: 'Full/'
        [parameter(Mandatory)]
        [string]
        $SourcePrefix,

        # The prefix for the destination prefix. E.g: 'FULL/'
        [parameter(Mandatory)]
        [string]
        $DestinationPrefix
    )

    $Results = Compare-Blobs -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -Container $Container -Prefix $SourcePrefix -ComparePrefix $DestinationPrefix

    $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

    foreach ($Result in $Results ) {

        if ($Result.Matched -eq $true -and $Result.SizeInMB -eq $Result.MatchSizeInMB) {

            if ($PSCmdlet.ShouldProcess($Result.Name, 'Remove-AzStorageBlob')) {
                Write-Host "$($Result.Name) already exists in destination, removing.."
                Remove-AzStorageBlob -Context $StorageContext -Blob $Result.Name -Container $Container
            }
        }
        else {
            try {
                $Destination = $Result.name -replace $SourcePrefix, $DestinationPrefix
                
                if ($PSCmdlet.ShouldProcess($Result.Name, "Copy-AzStorageBlob -DestBlob $Destination")) {
                    Write-Host "Copying $($Result.Name) to $Destination.."
                    Copy-AzStorageBlob -Context $StorageContext -SrcBlob $Result.Name -SrcContainer $Container -DestContainer $Container -DestBlob $Destination -ErrorAction Stop
                }

                if ($PSCmdlet.ShouldProcess($Result.Name, 'Remove-AzStorageBlob')) {
                    Write-Host "Removing $($Result.Name).."
                    Remove-AzStorageBlob -Context $StorageContext -Blob $Result.Name -Container $Container -ErrorAction Stop
                }
            }
            catch {
                Write-Error $_
            }
        }
    }
}
