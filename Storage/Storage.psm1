$Public = @( Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue )

@($Private + $Public) | ForEach-Object {
    try {
        . $_.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($_.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.Basename