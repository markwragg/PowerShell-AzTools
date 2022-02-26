function Set-EnvVariablesFromADORelease {
    <#
    .SYNOPSIS
        Retrieves variables from Azure DevOps and creates as local environment variables.
        
    .DESCRIPTION
        Gets the variables from an Azure DevOps Release pipeline and creates them as local environment variables.

    .NOTES
        Requires the VSTeam module.
    #>
    [cmdletbinding()]
    param(
        # The name of the Azure DevOps Account
        [Parameter(Mandatory)]
        [string]
        $Account,

        # The name of the Azure DevOps Project
        [Parameter(Mandatory)]
        [string]
        $ProjectName,

        # The name of the Azure DevOps Release from which to get matching parameter values
        [Parameter(Mandatory)]
        [string]
        $ReleaseName,

        # The name of the Environment
        [Parameter(Mandatory)]
        [string]
        $Environment,
        
        # An Azure DevOps Personal Access Token with suitable permissions to access the release
        [Parameter(Mandatory)]
        [string]
        $PAT
    )

    Write-Output '', 'Connecting to Azure DevOps..'

    Set-VSTeamAccount -Account $Account -PersonalAccessToken $PAT

    $ADOReleaseID = (Get-VSTeamReleaseDefinition -ProjectName $ProjectName | Where-Object { $_.Name -eq $ReleaseName }).Id
    $ADODefinition = Get-VSTeamReleaseDefinition -ProjectName $ProjectName -Id $ADOReleaseID
    $ADOEnvironment = $ADODefinition.Environments | Where-Object { $_.Name -eq $Environment }

    Write-Output '', "Removing any pre-existing ADO Environment variables.."

    foreach ($ADOVariable in $ADOEnvironment.Variables.psobject.properties.name) {

        if ([Environment]::GetEnvironmentVariable($ADOVariable)) {
            Write-Verbose "Removing Env:\$ADOVariable"
            Remove-Item "Env:\$ADOVariable" -Force
        }
    }

    foreach ($ADODefVariable in $ADODefinition.Variables.psobject.properties.name) {

        if ([Environment]::GetEnvironmentVariable($ADODefVariable)) {
            Write-Verbose "Removing Env:\$ADODefVariable"
            Remove-Item "Env:\$ADODefVariable" -Force
        }
    }

    Write-Output '', "Processing ADO Stage scope variables for $Environment.."

    foreach ($ADOVariable in $ADOEnvironment.Variables.psobject.properties.name) {

        if ($ADOEnvironment.variables.$ADOVariable.value -eq '$false') { $ADOEnvironment.variables.$ADOVariable.value = $false }

        do {
            $Result = $ADOEnvironment.variables.$ADOVariable.value | Select-String -Pattern '(?<=\$\()(.*?)(?=\))' -AllMatches
                    
            foreach ($Match in $Result.Matches) { 
                $SubParameter = $Match.value
                $ReplaceParameter = '$(' + $SubParameter + ')'
                $ReplaceValue = if ($ADOEnvironment.variables.$SubParameter.value) {
                    $ADOEnvironment.variables.$SubParameter.value
                }
                else {
                    $ADODefinition.variables.$SubParameter.value
                }
                Write-Verbose "Replacing $ReplaceParameter with $ReplaceValue.."
                $ADOEnvironment.variables.$ADOVariable.value = $ADOEnvironment.variables.$ADOVariable.value.replace($ReplaceParameter, $ReplaceValue)
            }
        } until (-not $Result)

        $Value = $ADOEnvironment.Variables.$ADOVariable.value

        if (-not [Environment]::GetEnvironmentVariable($ADOVariable) -and $Value) {
            Write-Verbose "Creating Env:\$ADOVariable with value $Value.."
            New-Item "Env:\$ADOVariable" -Value $Value | Out-Null
        }
    }

    Write-Output '', "Processing ADO Release scope variables.."

    foreach ($ADODefVariable in $ADODefinition.Variables.psobject.properties.name) {

        if ($ADODefinition.variables.$ADODefVariable.value -eq '$false') { $ADODefinition.variables.$ADODefVariable.value = $false }

        do {
            $Result = $ADODefinition.variables.$ADODefVariable.value | Select-String -Pattern '(?<=\$\()(.*?)(?=\))' -AllMatches
            
            foreach ($Match in $Result.Matches) { 
                $SubParameter = $Match.value
                $ReplaceParameter = '$(' + $SubParameter + ')'
                $ReplaceValue = if ($ADOEnvironment.variables.$SubParameter.value) {
                    $ADOEnvironment.variables.$SubParameter.value
                }
                else {
                    $ADODefinition.variables.$SubParameter.value
                }
                $ADODefinition.variables.$ADODefVariable.value = $ADODefinition.variables.$ADODefVariable.value.replace($ReplaceParameter, $ReplaceValue)
            }
        } until (-not $Result)
        
        $Value = $ADODefinition.Variables.$ADODefVariable.value
        
        if (-not [Environment]::GetEnvironmentVariable($ADODefVariable) -and $Value) {
            Write-Verbose "Creating Env:\$ADODefVariable with value $Value.."
            New-Item "Env:\$ADODefVariable" -Value $Value | Out-Null
        }
    }
}