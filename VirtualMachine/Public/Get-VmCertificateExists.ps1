function Get-VmCertificateExists {
    <#
    .SYNOPSIS
        Script to check if a certificate exists on one or more VMs via PS Remoting.
    #>
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(Mandatory)]
        [string[]]
        $ComputerName,

        [parameter(Mandatory, ParameterSetName = 'Path')]
        $CertPath,

        [parameter(Mandatory, ParameterSetName = 'CommonName')]
        [string]
        $CommonName,
    
        # The store in which to locate the certificate.
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string]
        $CertificateStore = 'LocalMachine'
    )
    begin { }    
    process {
        
        Invoke-Command -ComputerName $ComputerName { 

            if ($using:CommonName) {
                $CertCheck = Get-ChildItem Cert:\$CertificateStore -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Subject -like "*$($using:CommonName)*" }
            }
            elseif ($using:CertPath) {
                $CertCheck = Get-ChildItem $using:CertPath -ErrorAction SilentlyContinue
            }

            foreach ($Cert in $CertCheck) {
                [pscustomobject]@{
                    Exists     = $true
                    Path       = $Cert.psparentpath.split('::')[-1]
                    Subject    = $Cert.Subject
                    Thumbprint = $Cert.Thumbprint
                }
            }

            if (-not $CertCheck) {
                [pscustomobject]@{
                    Exists     = $false  
                    Path       = $null  
                    Subject    = $null
                    Thumbprint = $null
                }
            }
        } | Select-Object * -ExcludeProperty RunspaceId
    } 
}