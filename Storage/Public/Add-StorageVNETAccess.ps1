function Add-StorageVNETAccess {
    <#
    .SYNOPSIS
        Use to add a VNET and all of its subnets to the list of permitted networks for a specified Storage Account.    
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        # The Resource Group Name for the Storage Account to modify
        [parameter(Mandatory)]
        [string]
        $RGName,
        
        # The Name of the storage account to modify
        [parameter(Mandatory)]
        [string]
        $Name,

        # The Resource Group Name for the VNET to permit
        [parameter(Mandatory)]
        [string]
        $VNETRGName,
                
        # The Name of the VNET to permit
        [parameter(Mandatory)]
        [string]
        $VNETName
    )
    
    $ExistingRuleSet = Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $RGName -AccountName $Name -ErrorAction Stop

    $DefaultAction = $ExistingRuleSet.DefaultAction
    $ExistingRules = $ExistingRuleSet.VirtualNetworkRules

    if ($DefaultAction -ne 'Deny') {
        Write-Warning 'Storage Account default action is not Deny. VNET restrictions will be applied but will not be effective.'
    }

    $VNET = Get-AzVirtualNetwork -ResourceGroupName $VNETRGName -Name $VNETName -ErrorAction Stop
    
    foreach ($Subnet in $VNET.Subnets) {

        if ($Subnet.Id -notin $ExistingRules.VirtualNetworkResourceId) {

            if ($PSCmdlet.ShouldProcess($Name)) {
                
                $VNET | Set-AzVirtualNetworkSubnetConfig -Name $Subnet.Name -AddressPrefix $Subnet.AddressPrefix -ServiceEndpoint 'Microsoft.Storage' | Set-AzVirtualNetwork
                Add-AzStorageAccountNetworkRule -ResourceGroupName $RGName -Name $Name -VirtualNetworkResourceId $Subnet.Id
            }
        }
        else {
            Write-Verbose "$($Subnet.Name) is already assigned to $Name."
        }
    }
}