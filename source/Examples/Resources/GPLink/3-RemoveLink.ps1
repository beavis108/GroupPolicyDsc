<#
    .DESCRIPTION
        This example shows how to remove the link of a GPO from an
        organizational unit. The GPO itself is not removed.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPLink LegacyLink {
            Name   = 'Legacy Policy'
            Target = 'OU=Clients,DC=contoso,DC=com'
            Ensure = 'Absent'
        }
    }
}
