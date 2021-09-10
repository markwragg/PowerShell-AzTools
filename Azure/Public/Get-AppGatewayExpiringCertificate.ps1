function Get-AppGatewayExpiringCertificate {
    <#
    .SYNOPSIS
        Retrieves the SSL certificates assigned to each of the App Gateways across all subscriptions.

    .DESCRIPTION
        Useful to check the expiry date of the configured SSL certificates. Use -ExpiresInDays to filter
        for certificates expiring within a specified number of days.

    .EXAMPLE
        Get-AppGatewayExpiringCertificate -ExpiresInDays 90
    #>
    [CmdletBinding()]
    param(
        # Name of the subscription to query. If not provided then all subscriptions for the current context are checked.
        [string]
        $SubscriptionName,

        # Use to specify a specific App Gateway to query.
        [string]
        $AppGatewayName,

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

        $AppGateways = if ($AppGatewayName) {
            Get-AzApplicationGateway -Name $AppGatewayName
        }
        else {
            Get-AzApplicationGateway
        }

        foreach ($AppGateway in $AppGateways) {

            foreach ($SSLCert in $AppGateway.sslCertificates) {

                if (-not $SSLCert.publicCertData) {
                    $msg = 'Certificate {0} is linked to Key Vault secret: {1}. Certificate scanning is not supported in this scenario. You can leverage Azure Policy to do so.' -f $SSLCert.name, $SSLCert.keyVaultSecretId
                    Write-Warning $msg -Verbose
                }
                else {
                    $Data = [System.Convert]::FromBase64String($SSLCert.publicCertData.Substring(60, $SSLCert.publicCertData.Length - 60))
                    $Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]($Data)

                    if ($Cert.NotAfter -le $ExpirationDate -or -not $ExpiresInDays) {

                        [pscustomobject]@{
                            ResourceGroup   = $AppGateway.ResourceGroupName
                            Name            = $AppGateway.Name
                            CertificateName = $SSLCert.Name
                            NotAfter        = $Cert.NotAfter
                            Thumbprint      = $Cert.Thumbprint
                            Cert            = $Cert
                        }
                    }       
                }
            }
        }
    }
}