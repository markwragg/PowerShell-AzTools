function Compare-StorageBlobs {
    <#
    .SYNOPSIS
        Compares Blobs from one path to another within the same storage container to show those that contain matching file names.

    .EXAMPLE
        Compare-StorageBlobs -Prefix 'Full/' -ComparePrefix 'FULL/'
    #>
    [cmdletbinding()]
    param(
        [string]
        $StorageAccountName = 'proddbbkpstore',

        [string]
        $ResourceGroupName = 'prd-strg-ac',

        [string]
        $Container = 'packagedbbackup',

        [string]
        $Prefix = 'Tlog/',

        [string]
        $ComparePrefix = 'TLOG/'
    )

    $Blobs = Get-StorageBlobs -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Container $Container -Prefix '' -Limit 100000

    $RootBlobs = $Blobs | Where-Object { $_.Name -cmatch $Prefix }
    $CompareBlobs = $Blobs | Where-Object { $_.Name -cmatch $ComparePrefix }

    foreach ($Blob in $RootBlobs) {

        $MatchedBlob = $CompareBlobs | Where-Object { $_.name -ieq $Blob.name }

        $DatePattern = [Regex]::new('\d\d\d\d_\d\d_\d\d')
        $DateMatch = $DatePattern.Matches($Blob.name)
        $BlobDate = if ($DateMatch) {
            (Get-Date ($DateMatch.Value -replace '_', '-')).ToShortDateString()
        }      

        [PSCustomObject]@{
            Name          = $Blob.Name
            SizeInMB      = [math]::Round($Blob.Length / 1MB, 4)
            Matched       = [bool]$MatchedBlob
            Match         = $MatchedBlob.name
            MatchSizeInMB = [math]::Round($MatchedBlob.Length / 1MB, 4)
            Date          = $BlobDate
        }
    }
}
