#Requires -module Subnet
function Get-VNETAddressSpace {
    <#
    .SYNOPSIS
        Retrieve VNET address space details.
    #>
    [CmdletBinding()]
    param (
        [string]
        $SubscriptionName
    )

    $Subscriptions = if ($SubscriptionName) {
        (Get-AzSubscription -SubscriptionName $SubscriptionName).Name
    }
    else {
        (Get-AzSubscription).Name
    }

    $AllVNETs = foreach ($Subscription in $Subscriptions) {

        Select-AzSubscription -SubscriptionName $Subscription | Out-Null

        $VNETs = Get-AzVirtualNetwork 
        
        foreach ($VNET in $VNETs) {

            foreach ($AddressSpace in $VNET.AddressSpace.AddressPrefixes) {

                $Subnet = Get-Subnet -IP $AddressSpace
                
                [PSCustomObject]@{
                    Subscription      = $Subscription
                    ResourceGroupName = $VNET.ResourceGroupName
                    Name              = $VNET.Name
                    AddressSpace      = $AddressSpace
                    Range             = $Subnet.Range 
                }
            }
        }
    }

    $AllVNETs | Sort-Object AddressSpace
}