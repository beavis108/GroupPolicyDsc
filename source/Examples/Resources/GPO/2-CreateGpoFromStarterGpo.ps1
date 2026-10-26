<#
    .DESCRIPTION
        This example shows how to create a Starter GPO and a GPO that is
        created from the Starter GPO and filtered with an existing WMI filter.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPStarterGPO ClientTemplate {
            Name    = 'Client Template'
            Comment = 'Template for client GPOs.'
        }

        GPO ClientSettings {
            Name           = 'Client Settings'
            StarterGpoName = 'Client Template'
            WmiFilterName  = 'Windows 11'
            DependsOn      = '[GPStarterGPO]ClientTemplate'
        }
    }
}
