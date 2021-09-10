Describe 'Get-NSGIPWhitelist' {

    BeforeAll { 
        . $PSScriptRoot\..\Public\Get-NSGIPWhitelist.ps1    
        
        Mock Select-AzSubscription { }

        Mock Get-AzNetworkSecurityGroup { 
            [PSCustomObject]@{
                Name = 'testnsg1'
                SecurityRules = @{
                    Name = 'testrule_http'
                    Direction = 'Inbound'
                    DestinationPortRange = 80
                    SourceAddressPrefix = '1.2.3.4'
                }
            },
            [PSCustomObject]@{
                Name = 'testnsg2'
                SecurityRules = @(@{
                    Name = 'testrule_https'
                    Direction = 'Inbound'
                    DestinationPortRange = 443
                    SourceAddressPrefix = '10.20.30.40'
                },
                @{
                    Name = 'testrule_http'
                    Direction = 'Inbound'
                    DestinationPortRange = 80
                    SourceAddressPrefix = '10.20.30.40','200.0.0.1'
                })
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

            Get-NSGIPWhitelist
        }

        It 'Should Select 3 Subscriptions' {
            Should -Invoke Select-AzSubscription -Exactly 3
        }
        It 'Should Invoke Get-AzNetworkSecurityGroup 3 times' {
            Should -Invoke Get-AzNetworkSecurityGroup -Exactly 3
        }
    }

    Context '-SubscriptionName specified' {

        BeforeEach {
            Mock Get-AzSubscription { 
                [PSCustomObject]@{ Name = 'fakesubscription1' }
            }

            Get-NSGIPWhitelist -SubscriptionName 'fakesubscription1'
        }

        It 'Should Select 1 Subscription' {
            Should -Invoke Select-AzSubscription -Exactly 1
        }
        It 'Should Invoke Get-AzNetworkSecurityGroup 1 time' {
            Should -Invoke Get-AzNetworkSecurityGroup -Exactly 1
        }
    }

    Context '-SubscriptionName specified for a non-existing subscription' {

        BeforeEach {
            Mock Get-AzSubscription { }

            Get-NSGIPWhitelist -SubscriptionName 'notarealsubscription'
        }

        It 'Should Select 0 Subscriptions' {
            Should -Invoke Select-AzSubscription -Exactly 0
        }
        It 'Should Invoke Get-AzNetworkSecurityGroup 0 times' {
            Should -Invoke Get-AzNetworkSecurityGroup -Exactly 0
        }
    }
}