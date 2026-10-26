<#
    .DESCRIPTION
        This example shows how to create a Starter GPO.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPStarterGPO ServerTemplate {
            Name    = 'Server Template'
            Comment = 'Template for all server GPOs.'
        }
    }
}
