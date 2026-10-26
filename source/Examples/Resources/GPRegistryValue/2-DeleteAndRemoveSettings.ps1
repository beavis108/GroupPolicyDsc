<#
    .DESCRIPTION
        This example shows the difference between a setting that deletes a
        value on the clients (PolicyState 'Delete') and a setting that is
        removed from the GPO (Ensure 'Absent', not configured).
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPRegistryValue DeleteLegacyValue {
            Name        = 'Server Baseline'
            Key         = 'HKLM\Software\Policies\Contoso\Agent'
            ValueName   = 'LegacyServer'
            PolicyState = 'Delete'
        }

        GPRegistryValue NotConfigured {
            Name      = 'Server Baseline'
            Key       = 'HKLM\Software\Policies\Contoso\Agent'
            ValueName = 'DebugLevel'
            Ensure    = 'Absent'
        }
    }
}
