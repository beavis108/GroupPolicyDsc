<#
    .DESCRIPTION
        This example shows how to remove a GPO and all its links.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPO LegacyPolicy {
            Name   = 'Legacy Policy'
            Ensure = 'Absent'
        }
    }
}
