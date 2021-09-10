
function Get-AppServiceCertificate {
    <#
    .SYNOPSIS
        Retrieves the App Service Certificates for the current subscription.

    .DESCRIPTION
        Useful to check the expiry date of the App Service Certificates. Use -ExpiresInDays to filter
        for certificates expiring within a specified number of days.

    .EXAMPLE
        Get-AppServiceCertificate -ExpiresInDays 90
    #>
    [CmdletBinding()]
    param(
        # Name of the subscription to query. If not provided then all subscriptions for the current context are checked.
        [string]
        $SubscriptionName,

        # Use to specify a specific App Service Certificate to query.
        [string]
        $CertificateName,

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

        $Certs = if ($CertificateName) {
            Get-AzResource -Name $CertificateName -ResourceType Microsoft.CertificateRegistration/certificateOrders -ExpandProperties
        }
        else {
            Get-AzResource -ResourceType Microsoft.CertificateRegistration/certificateOrders -ExpandProperties
        }

        foreach ($Cert in $Certs) {

            if ([datetime]$Cert.properties.expirationTime -le $ExpirationDate -or -not $ExpiresInDays) {

                [pscustomobject]@{
                    ResourceGroup = $Cert.ResourceGroupName
                    Name          = $Cert.Name
                    Subject       = $Cert.properties.signedCertificate.subject
                    Expiry        = [datetime]$Cert.properties.expirationTime
                    ValidDays     = ([datetime]$Cert.properties.expirationTime - (Get-Date)).Days
                    Thumbprint    = $Cert.properties.signedCertificate.thumbprint
                    Version       = $Cert.properties.signedCertificate.version
                }
            }       
        }
    }
}