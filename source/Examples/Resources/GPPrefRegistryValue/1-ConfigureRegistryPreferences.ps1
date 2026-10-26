<#
    .DESCRIPTION
        This example shows how to configure Registry preference items in the
        computer and in the user configuration of a GPO.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPPrefRegistryValue AgentServer {
            Name      = 'Client Settings'
            Context   = 'Computer'
            Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso\Agent'
            ValueName = 'Server'
            Action    = 'Update'
            Type      = 'String'
            Value     = 'agent.contoso.com'
        }

        GPPrefRegistryValue AgentPorts {
            Name      = 'Client Settings'
            Context   = 'Computer'
            Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso\Agent'
            ValueName = 'Ports'
            Action    = 'Replace'
            Type      = 'MultiString'
            Value     = '443', '8443'
        }

        GPPrefRegistryValue HomePage {
            Name      = 'Client Settings'
            Context   = 'User'
            Key       = 'HKEY_CURRENT_USER\SOFTWARE\Contoso\Portal'
            ValueName = 'StartPage'
            Type      = 'String'
            Value     = 'https://intranet.contoso.com'
        }
    }
}
