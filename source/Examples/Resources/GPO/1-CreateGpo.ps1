<#
    .DESCRIPTION
        This example shows how to create a GPO with a comment that only
        contains computer settings (the user configuration is disabled).
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPO ServerBaseline {
            Name    = 'Server Baseline'
            Domain  = 'contoso.com'
            Comment = 'Security baseline for all member servers. Managed by DSC.'
            Status  = 'UserSettingsDisabled'
        }
    }
}
