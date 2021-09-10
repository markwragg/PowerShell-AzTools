#Requires -Module MarkdownPS
param(
    [switch]
    $AsMarkdown
)

$Modules = Get-ChildItem -Path $PSScriptRoot -Filter *.psm1 -Recurse 

$Modules | ForEach-Object { 
    Import-Module $_.FullName -Force
}

$Cmdlets = (Get-Module $Modules.BaseName).ExportedFunctions.Keys

$Result = foreach ($Cmdlet in $Cmdlets) { 
    $CmdletHelp = Get-Help $Cmdlet
    
    [PSCustomObject][ordered]@{
        Module = $CmdletHelp.ModuleName
        Cmdlet = $CmdletHelp.Name
        Description = $CmdletHelp.Synopsis
    }
}

if ($AsMarkdown) {
    $Result | New-MDTable
}
else {
    $Result
}