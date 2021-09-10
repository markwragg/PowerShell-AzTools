function Get-NSGIPWhitelist {
    <#
    .SYNOPSIS
        Script to retrieve the IP Whitelists on the NSGs.

    .DESCRIPTION
        Gets the Network Security Group config for all subscriptions where a rule allows either port
        80 or 443 Inbound and returns the SourceAddressPrefix lists for these rules which (where applied)
        work as an IP whitelist.

    .EXAMPLE
        .\Get-NSGIPWhitelist.ps1

    .EXAMPLE
        Get-NSGIPWhitelist
    #>
    #>
    [CmdletBinding()]
    param(
        # Name of the subscription to query. If not provided then all subscriptions for the current context are checked.
        [string]
        $SubscriptionName
    )

    $Subscriptions = if ($SubscriptionName) {
        Get-AzSubscription -SubscriptionName $SubscriptionName
    }
    else {
        Get-AzSubscription
    }

    foreach ($Subscription in $Subscriptions) {

        $Subscription | Select-AzSubscription | Out-Null

        $NSGs = Get-AzNetworkSecurityGroup

        foreach ($NSG in $NSGs) {

            $Rules = $NSG.SecurityRules | Where-Object { $_.Direction -eq 'Inbound' -and ($_.DestinationPortRange -contains 80 -or $_.DestinationPortRange -contains 443) }
        
            foreach ($Rule in $Rules) {
            
                [PSCustomObject]@{
                    NSGName   = $NSG.Name
                    Rule      = $Rule.Name
                    WhiteList = ($Rule.SourceAddressPrefix | ForEach-Object { $_ | Sort-Object { $_ -as [version] }}) -Join ', '
                    WLCount   = $Rule.SourceAddressPrefix.Count
                }
            }
        }
    }
}