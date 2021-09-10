function Get-StorageBlobs {
    <#
    .SYNOPSIS
        Retrieves all Blobs a specified storage container and returns their name, length and last modified date.

    .EXAMPLE
        Get-StorageBlobs -StorageAccountName 'mystorageaccount' -ResourceGroupName 'myresourcegroup'
    #>
    param(
        [parameter(Mandatory)]
        [string]
        $StorageAccountName,

        [string]
        $ResourceGroupName,

        [string]
        $Container,

        [string]
        $Prefix = 'FULL',

        [int]
        $Limit = 10
    )

    if (-not $ResourceGroupName) {
        $ResourceGroupName = (Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $StorageAccountName }).ResourceGroupName
    }
        
    $Key = (Get-AzStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName)[0].value
    $Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $Key
        
    $Containers = if ($Container) { 
        $Container 
    }
    else { 
        (Get-AzStorageContainer -Context $Context).Name
    }
        
    foreach ($Container in $Containers) {
        
        $Blobs = @()
        Write-Verbose $Container
    
        do {
            $Blobs += Get-AzStorageBlob -Container $Container -Context $Context -Prefix $Prefix -ContinuationToken $Token
            if ($Blobs.Length -le 0) { Break }
            $Token = $Blobs[$Blobs.Count - 1].ContinuationToken;
        }
        While ($Null -ne $Token)

        $Blobs | Sort-Object LastModified -Descending | Select-Object -First $Limit Name, Length, LastModified
    }
}