function Invoke-ARMDeployment {
    <#
    .SYNOPSIS
        This script is to validate or execute ARM deployments.

    .DESCRIPTION
        Script to generate the WhatIf output or perform the execution of an ARM template. Input values for the ARM template can either be specified 
        via -TemplateParams, -ParamFile or the script will automatically match ARM template parameters to environment variables of the same name. 
        
        By default this script does not execute a deployment. You must use the -RunDeployment switch when you are ready to deploy.

    .NOTES
        Requires the Az module.
    #>
    [cmdletbinding()]
    Param(
        # The deployment mode for the ARM deployment, either Incremental or Complete (Default: Incremental)
        [string]
        $Mode = 'Incremental',

        # The name of the Resource Group being targetted for the ARM deployment.
        [Parameter(Mandatory)]
        [string]
        $ResourceGroupName,

        # Path to the ARM template file you want to validate.
        [Parameter(Mandatory)]
        [string]
        $TemplateFile,

        # Optional: A hashtable object containing key/value pairs to be used as input values for the template.
        [hashtable]
        $TemplateParams,

        # Optional: Path to the ARM template parameter file.
        [string]
        $ParamFile,

        # Optional: The name of the KeyVault from which to retrieve secrets.
        [string]
        $KVName,

        # Optional: A hashtable object containing key/value pairs to map variables to secret names in the KeyVault specified by -KVName.
        [hashtable]
        $SecretParams,

        # Use to skip the ARM template validation check.
        [switch]
        $SkipValidation,

        # Use to execute the ARM template deployment.
        [switch]
        $RunDeployment,

        # Disable the What If output to include ANSI colour codes
        [switch]
        $NoColourOutput
    )

    function Format-ValidationOutput ($ValidationOutput, [int] $Depth = 0) {
        <#
        .SYNOPSIS
            Improves the formatting of any validation errors.
        #>
        return @(
            $ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { 
                @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) 
            }
        )
    }
    function Add-TemplateParameter ($Name, $Value, $AsType, $Source) {
        <#
        .SYNOPSIS
            Adds a template parameter to the $TemplateParams hashable and returns its details.
        #>
        if ($AsType) {
            $Value = $Value -As $AsType
        }
        elseif ($Value) {
            $AsType = $Value.GetType().Name
        }

        if ($Name -notin $TemplateParams.Keys) {
            $TemplateParams.Add($Name, $Value)
        }

        if ($Name -notin $ParameterResult.Name) {
            [PSCustomObject]@{
                Name   = $Name
                Source = $Source
                Type   = $AsType
                Value  = $Value
            }
        }
    }
    function Add-TemplateParameterFromKeyVault ($Name, $KVName, $SecretName, $AsType, $Source) {
        <#
    .SYNOPSIS
        Adds a template parameter from a secret in KeyVault.
    #>
        $Secret = Get-AzKeyVaultSecret -VaultName $KVName -name $SecretName
        $SecretValue = if ($AsType -eq 'SecureString') { $Secret.SecretValue }  else { $Secret.Id }

        if ($SecretValue) {
            Add-TemplateParameter -Name $Name -Value $SecretValue -Source $Source
        }
        else {
            Write-Error "A value for $Name from Secret $SecretName in $KVName could not be found."
        }
    }

    # Infer the ARM template parameters file name if it has not been provided
    if (-not $ParamFile) {
        $ParamFile = $TemplateFile.replace('.json', '.parameters.json')
    }

    # Create an empty hashtable for the ARM template input parameters if none have been provided via the -TemplateParams parameter.
    if (-not $TemplateParams) {
        $TemplateParams = @{ }
    }

    $Template = Get-Content $TemplateFile | ConvertFrom-Json
    
    if (Test-Path $ParamFile) {
        $TemplatePF = Get-Content $ParamFile | ConvertFrom-Json
    }

    # Array to store the discovered parameters so they can be output later
    $ParameterResult = @()

    # Get the list of parameters from the ARM template
    $ParameterNames = $Template.parameters.psobject.properties.name

    # _artifactsLocation and _artifactsLocationSasToken are known parameters that need to map to the storage account that contains the ARM template files
    $ParameterResult += if ('_artifactsLocation' -in $ParameterNames -and '_artifactsLocationSasToken' -notin $TemplateParams.Keys) {

        $AccountKeys = Get-AzStorageAccountKey -ResourceGroupName $Env:ARMSupportFilesRGName -Name $Env:StorageAccount
        $StorageAccountContext = New-AzStorageContext -StorageAccountName $Env:storageAccount -StorageAccountKey $AccountKeys[0].Value 
        $artifactsStorageContainer = Get-AzStorageContainer -Name $Env:StorageContainer -Context $storageAccountContext
        $ArtifactsLocationSasToken = New-AzStorageContainerSASToken -Container $artifactsStorageContainer.Name -Context $StorageAccountContext -Permission r
    
        Add-TemplateParameter -Name '_artifactsLocation' -Value $artifactsStorageContainer.CloudBlobContainer.uri.AbsoluteUri -Source 'Script'
        Add-TemplateParameter -Name '_artifactsLocationSasToken' -Value $ArtifactsLocationSasToken -Source 'Script'
    }

    # Iterate through the list of parameters in the ARM template and attempt to map an input value for each
    $ParameterResult += foreach ($ParameterName in $ParameterNames) {

        $Type = $Template.Parameters.$ParameterName.type
        
        # Parameter value has already been provided via the -TemplateParams input parameter.
        if ($ParameterName -in $TemplateParams.Keys) {

            # If a string value has been provided for a template parameter that requires a securestring, convert it to securestring
            if ($Type -eq 'SecureString' -and $TemplateParams[$ParameterName] -isnot [securestring]) {
                $TemplateParams[$ParameterName] = [securestring]($TemplateParams[$ParameterName] | ConvertTo-SecureString -AsPlainText -Force)
            }

            Add-TemplateParameter -Name $ParameterName -Value $TemplateParams[$ParameterName] -Source 'ScriptInput'
        }
        else {
            # Get the environment variable value for the parameter name, if it exists
            $EnvValue = Get-Item Env:\$ParameterName -ErrorAction SilentlyContinue

            # If the Environment Value contains the string '$false' convert it to the boolean equivalent
            if ($EnvValue.Value -eq '$false') { $EnvValue = $false }
        
            # Attempt to map a value to the template parameter from each of the known locations, in the specified priority order
            if ($EnvValue) {
                # Use the value from the Environment Variable of the same name
                Add-TemplateParameter -Name $ParameterName -Value $EnvValue.Value -AsType $Type -Source 'EnvironmentVariable'
            }
            elseif ($ParameterName -in $SecretParams.Keys) {
                # Use the value for the Secret specified in the list of Known Secrets from the KeyVault specified via -KvName
                $KVSecretName = $SecretParams[$ParameterName]
                Add-TemplateParameterFromKeyVault -Name $ParameterName -KVName $KVName -SecretName $KVSecretName -AsType $Type -Source 'KeyVaultSecret'
            }
            elseif ($TemplatePF.Parameters.$ParameterName.reference.keyVault) {
                # Retrieve the Key Vault secret named in the Parameter
                $PFKVName = ($TemplatePF.Parameters.$ParameterName.reference.keyVault.Id -split '/')[-1]
                $PFKVSecretName = $TemplatePF.Parameters.$ParameterName.reference.secretName
                Add-TemplateParameterFromKeyVault -Name $ParameterName -KvName $PFKVName -SecretName $PFKVSecretName -AsType 'SecureString' -Source 'ParameterFileKeyVaultSecret'
            }
            elseif ($TemplatePF.Parameters.$ParameterName.value) {
                # Use the value provided via the Parameter File
                $PFValue = $TemplatePF.Parameters.$ParameterName.value
                Add-TemplateParameter -Name $ParameterName -Value $PFValue -AsType $Type -Source 'ParameterFileValue'
            }
            elseif ($Template.Parameters.$ParameterName.defaultValue) {
                # Use the template Default Value
                $DefaultValue = $Template.Parameters.$ParameterName.defaultValue
                Add-TemplateParameter -Name $ParameterName -Value $DefaultValue -AsType $Type -Source 'TemplateDefaultValue'
            }
            else {
                # No value was matched. This may mean the ARM template will fail as a required input has not been given a value.
                Write-Warning "No value found for $ParameterName"
            }
        }
    }

    # Output a list of the template parameters and values indicating where each value was sourced from and their types
    Write-Output '', 'Template parameter discovery result..'
    $ParameterResult | Sort-Object Name | Format-Table -Wrap -AutoSize | Out-String -Width 2048

    $DeployParams = @{
        Mode                        = $Mode 
        ResourceGroupName           = $ResourceGroupName 
        TemplateFile                = $TemplateFile 
        TemplateParameterObject     = $TemplateParams 
        SkipTemplateParameterPrompt = $true
    }

    # Perform a validation check of the ARM template (ensures it is syntactically correct and has all mandatory inputs)
    if (-not $SkipValidation) {

        Write-Output '', 'Validating template..'
        $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment @DeployParams)

        if ($ErrorMessages) {
            Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
            Write-Error 'Validation failed.'
        }
        else {
            Write-Output '', 'Template is valid.'
        }
    }

    # Generate WhatIf output for the ARM deployment to show which resources would be created, deleted or modified.
    if (-not $RunDeployment) {

        Write-Output '', 'Generating What If Result..'
        $Result = Get-AzResourceGroupDeploymentWhatIfResult @DeployParams -ResultFormat FullResourcePayloads 

        if (-not $NoColourOutput) {
            $Result
        }
        else {
            # Remove ANSI colour codes because Azure DevOps Release pipelines don't support them at the moment
            $Result | Out-String -Width 4096 | ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' }
        }
    }
    else {
        # Execute the ARM deployment, if the -RunDeployment switch has been provided.
        Write-Output '', 'Executing deployment..'
        $DeploymentDate = (Get-Date).ToString("yyyyMMdd-HHmm")

        # Switch to Continue so multiple errors can be formatted and output
        $ErrorActionPreference = 'Continue'
        New-AzResourceGroupDeployment @DeployParams -Name "AzureDeploy-$DeploymentDate" -Verbose -ErrorVariable ErrorMessages
        $ErrorActionPreference = 'Stop' 
    
        if ($ErrorMessages) {
            Write-Output '', 'Template deployment returned the following errors:', '', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message })
            Write-Error 'Deployment failed.'
        }
    }
}