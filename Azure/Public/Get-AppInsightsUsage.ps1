Function Get-AppInsightsUsage {
    <#
        .SYNOPSIS
            Returns the retention, cap and usage information for one or more AppInsights accounts.
    #>
    [cmdletbinding()]
    Param(
        # Optional: One or more AppInsights resource names
        [string[]]
        $Name
    )

    $AppInsights = Get-AzApplicationInsights

    If ($Name) { $AppInsights = $AppInsights | Where-Object { $_.Name -in $Name } }

    ForEach ($AI in $AppInsights) {
        # Get Daily Cap
        $DailyCap = Set-AzApplicationInsightsDailyCap -ResourceGroupName $AI.ResourceGroupName -Name $AI.Name

        # Get last 24 hours of usage
        $Permissions = @('ReadTelemetry', 'WriteAnnotations')

        $APIKey = Get-AzApplicationInsightsApiKey -ResourceGroupName $AI.ResourceGroupName -Name $AI.Name | Where-Object { $_.Description -eq 'GetAppInsightsUsageKey' }

        If (-not $APIKey) {
            $APIKey = New-AzApplicationInsightsApiKey -ResourceGroupName $AI.ResourceGroupName -Name $AI.Name -Permissions $Permissions -Description 'GetAppInsightsUsageKey'
        }
        
        $AppId = $AI.AppId

        $Headers = @{ 
            'X-Api-Key'    = $APIKey.ApiKey
            'Content-Type' = 'application/json' 
        }

        $Query = 'systemEvents
            | where timestamp >= ago(24h)
            | where type == "Billing"
            | extend BillingTelemetryType = tostring(dimensions["BillingTelemetryType"])
            | extend BillingTelemetrySizeInBytes = todouble(measurements["BillingTelemetrySize"])
            | summarize sum(BillingTelemetrySizeInBytes)'

        $EscapedQuery = [uri]::EscapeUriString("?query=$Query")

        $Result = Invoke-RestMethod -uri "https://api.applicationinsights.io/v1/apps/$AppId/query$EscapedQuery" -Headers $Headers

        $Usage = [Math]::Round($Result.tables.rows[0] / 1GB, 2)

        Remove-AzApplicationInsightsApiKey -ApiKeyId $APIKey.Id -ResourceGroupName $AI.ResourceGroupName -Name $AI.Name

        # Get Retention in Days
        $AzProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        
        if (-not $azProfile.Accounts.Count) {
            Write-Error "Ensure you have logged in before calling this function."    
        }
        
        $CurrentAzureContext = Get-AzContext
        $ProfileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($AzProfile)
        $Token = $ProfileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
        $UserToken = $Token.AccessToken
        
        $RequestUri = "https://management.azure.com/subscriptions/$($CurrentAzureContext.Subscription.Id)/resourceGroups/$($AI.ResourceGroupName)/providers/Microsoft.Insights/components/$($AI.Name)?api-version=2015-05-01"
        
        $Headers = @{
            "Authorization"         = "Bearer $UserToken"
            "x-ms-client-tenant-id" = $currentAzureContext.Tenant.TenantId
        }
        # Get Component object via ARM
        $GetResponse = Invoke-RestMethod -Method "GET" -Uri $RequestUri -Headers $Headers 

        # RetentionInDays property
        $RetentionInDays = $GetResponse.properties.RetentionInDays

        [pscustomobject]@{
            Name          = $AI.Name
            ResourceGroup = $AI.ResourceGroupName
            Retention     = $RetentionInDays
            DailyCap      = $DailyCap.Cap
            Usage         = $Usage
        }
    }
}