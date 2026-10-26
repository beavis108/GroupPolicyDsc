<#
    .DESCRIPTION
        This example shows how to link a GPO to two organizational units.
        The link to the OU 'Servers' gets the link order 1 (highest
        precedence), the link to the OU 'Test' is created disabled.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPO ServerBaseline {
            Name = 'Server Baseline'
        }

        GPLink ServerBaselineServers {
            Name      = 'Server Baseline'
            Target    = 'OU=Servers,DC=contoso,DC=com'
            Order     = 1
            DependsOn = '[GPO]ServerBaseline'
        }

        GPLink ServerBaselineTest {
            Name        = 'Server Baseline'
            Target      = 'OU=Test,OU=Servers,DC=contoso,DC=com'
            LinkEnabled = $false
            DependsOn   = '[GPO]ServerBaseline'
        }
    }
}
