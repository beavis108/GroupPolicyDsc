<#
    .DESCRIPTION
        This example shows how to link a GPO to an Active Directory site and
        enforce the link, so it can not be blocked by organizational units.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPLink BranchProxy {
            Name     = 'Branch Proxy Settings'
            Target   = 'CN=Berlin,CN=Sites,CN=Configuration,DC=contoso,DC=com'
            Enforced = $true
        }
    }
}
