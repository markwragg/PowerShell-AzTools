function Get-APIManagementExpiringCertificate {
    <#
    .SYNOPSIS
        Retrieves the SSL certificates assigned to each of the API Management resources across all subscriptions.

    .DESCRIPTION
        Useful to check the expiry date of the configured SSL certificates. Use -ExpiresInDays to filter
        for certificates expiring within a specified number of days.

    .EXAMPLE
        Get-APIManagementExpiringCertificate -ExpiresInDays 90
    #>
    [CmdletBinding()]
    param(
        # Name of the subscription to query. If not provided then all subscriptions for the current context are checked.
        [string]
        $SubscriptionName,

        # Use to specify a specific App Gateway to query.
        [string]
        $APIManagementName,

        # Filters the certificates returned to only those that expire in less than or equal to the number of days specified.
        [int]
        $ExpiresInDays
    )

    $ExpirationDate = (Get-Date).AddDays($ExpiresInDays)

    $Subscriptions = if ($SubscriptionName) {
        Get-AzSubscription -SubscriptionName $SubscriptionName
    }
    else {
        Get-AzSubscription
    }

    foreach ($Subscription in $Subscriptions) {

        $Subscription | Select-AzSubscription | Out-Null

        $APIs = if ($APIManagementName) {
            Get-AzApiManagement -Name $APIManagementName
        }
        else {
            Get-AzApiManagement
        }

        foreach ($API in $APIs) {

            foreach ($Cert in $API.ProxyCustomHostnameConfiguration.CertificateInformation) {

                if ($Cert) {
            
                    if ($Cert.Expiry -le $ExpirationDate -or -not $ExpiresInDays) {

                        [pscustomobject]@{
                            ResourceGroup = $API.ResourceGroupName
                            Name          = $API.Name
                            Subject       = $Cert.Subject
                            Expiry        = $Cert.Expiry
                            Thumbprint    = $Cert.Thumbprint
                        }
                    }       
                }
            }
        }
    }
}