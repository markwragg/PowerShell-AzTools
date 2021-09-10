Describe 'Get-AppGatewayExpiringCertificate' {

    BeforeAll { 
        . $PSScriptRoot\..\Public\Get-AppGatewayExpiringCertificate.ps1

        $SampleCert = 'a' * 60 + 
            'MIIDMzCCAhugAwIBAgIBATANBgkqhkiG9w0BAQsFADBHMRMwEQYDVQQDDApNYXJr
            IFdyYWdnMQswCQYDVQQGEwJHQjEjMCEGCSqGSIb3DQEJARYUbWFyay53cmFnZ0Bn
            bWFpbC5jb20wHhcNMjEwNzA1MjAyMzMzWhcNMjIwNzA1MjAyMzMzWjBHMRMwEQYD
            VQQDDApNYXJrIFdyYWdnMQswCQYDVQQGEwJHQjEjMCEGCSqGSIb3DQEJARYUbWFy
            ay53cmFnZ0BnbWFpbC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
            AQCojmQtDFgPErLybQNanKaRSwQ02lYg3YVgChZl8qvEPlkQ47RiLYKv9RwWN1Yv
            lhE8Qp5j5ez3X9V5gnFAm6MCaSQmuOeKKU2zFYfJbBVDGwpCsdnegqIB/j4BJLCS
            0STOsuVJ/Q7sEn9yYweelCUHvaNlhj2aAJN8q4hkfWt1pnUPRJ4LrknACS/sbTYF
            U5tHrXgKAGKx1rfnuJxv7wB3z4CLRsaxmk1knKgXuAe3XhJyEEbWA2dm7fzVTaHg
            8Dr+ngJzwOpdjaUVtvpuCMNXlsCuVIuC3E+C/kgBTZW/WkEYUKqmsGxKe5wZjj6G
            18jKzdDCK0HWN71bb3x3ZIazAgMBAAGjKjAoMA4GA1UdDwEB/wQEAwIFoDAWBgNV
            HSUBAf8EDDAKBggrBgEFBQcDATANBgkqhkiG9w0BAQsFAAOCAQEAjTTMdavXa60c
            jwpMkq8giUTDi84dylrVO4b5QJhzfQgHlNmPD3VtlkkbazXSTBujCVDXpzY5jsDm
            JAUKbbQncNaCAhkFFyHNp9JtLX29WMyh4zXAWe9XlScj2de9C4CHwtk5xmTOepxs
            eM0mvHPRo8l8bRMm9K3t7H6pFl+j4ni5WSZ1GHrnrLgZuL5M8+dUJrYgf7ydBAzq
            F6BahziD0eQ6VPYQePQ98SjuA2XBmGrr6zpxGTA4x23MlllbldZ5l3a7XSflkyP/
            PXPExbBk/gvjCEmo7GymVgb4qXg1VvcNjzt6nBA7vj4BaLqY7P9kUpwnU1d/yqxK
            aaaaaaaaaa=='

        Mock Select-AzSubscription { }

        Mock Get-AzApplicationGateway { 
            [PSCustomObject]@{
                Name              = 'testappgw1'
                ResourceGroupName = 'testrg'
                sslCertificates   = @{
                    publicCertData = $SampleCert
                }
            }
        }
    }

    Context 'No parameters' {

        BeforeEach {
            Mock Get-AzSubscription { 
                [PSCustomObject]@{ Name = 'fakesubscription1' }
                [PSCustomObject]@{ Name = 'fakesubscription2' }
                [PSCustomObject]@{ Name = 'fakesubscription3' }
            }

            $Result = Get-AppGatewayExpiringCertificate
        }

        It 'Should Select 3 Subscriptions' {
            Should -Invoke Select-AzSubscription -Exactly 3
        }
        It 'Should Invoke Get-AzApplicationGateway 3 times' {
            Should -Invoke Get-AzApplicationGateway -Exactly 3
        }
        It 'Should return a certificate expiry' {
            [datetime]$Result[0].NotAfter | Should -eq ('2022-07-05T21:23:33.0000000+01:00' | Get-Date)
        }
        It 'Should return a certificate thumbprint' {
            $Result[0].Thumbprint | Should -eq 'B5BE11461A3B3B8B2D96C0374AC53A81B9F6E495'
        }
    }

    Context '-SubscriptionName specified' {

        BeforeEach {
            Mock Get-AzSubscription { 
                [PSCustomObject]@{ Name = 'fakesubscription1' }
            }

            $Result = Get-AppGatewayExpiringCertificate -SubscriptionName 'fakesubscription1'
        }

        It 'Should Select 1 Subscription' {
            Should -Invoke Select-AzSubscription -Exactly 1
        }
        It 'Should Invoke Get-AzApplicationGateway 1 time' {
            Should -Invoke Get-AzApplicationGateway -Exactly 1
        }
        It 'Should return a certificate expiry' {
            [datetime]$Result.NotAfter | Should -eq ('2022-07-05T21:23:33.0000000+01:00' | Get-Date)
        }
        It 'Should return a certificate thumbprint' {
            $Result.Thumbprint | Should -eq 'B5BE11461A3B3B8B2D96C0374AC53A81B9F6E495'
        }
    }

    Context '-SubscriptionName specified for a non-existing subscription' {

        BeforeEach {
            Mock Get-AzSubscription { }

            $Result = Get-AppGatewayExpiringCertificate -SubscriptionName 'notarealsubscription'
        }

        It 'Should Select 0 Subscriptions' {
            Should -Invoke Select-AzSubscription -Exactly 0
        }
        It 'Should Invoke Get-AzApplicationGateway 0 times' {
            Should -Invoke Get-AzApplicationGateway -Exactly 0
        }
        It 'Should return no results' {
            $Result | Should -Be $null
        }
    }
}