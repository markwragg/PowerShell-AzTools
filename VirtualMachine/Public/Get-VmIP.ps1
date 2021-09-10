function Get-VmIP {
    <#
    .SYNOPSIS
        Returns the private IP addresses for all VMs in the current subscription.
    #>
    [cmdletbinding()]
    param()

    $Interfaces = Get-AzNetworkInterface

    foreach ($Interface in $Interfaces) {

        if ($Interface.VirtualMachine) {
            $VMName = $Interface.VirtualMachine.Id.split('/')[-1]
            $PrivateIP = $Interface.IpConfigurations.PrivateIpAddress
            
            $PublicIP = if ($Interface.IpConfigurations.publicIpAddress) {
                Get-AzPublicIpAddress -Name ($instance.IpConfigurations.publicIpAddress.Id.Split('/')[-1]).IpAddress
            }
        
            [PSCustomObject]@{
                VMName    = $VMName
                RGName    = $Interface.ResourceGroupName
                PrivateIP = $PrivateIP
                PublicIP  = $PublicIP
            }
        }
    }
}