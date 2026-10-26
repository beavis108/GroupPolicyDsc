<#
    .DESCRIPTION
        This example shows how to rename the GPO 'Old Server Policy' to
        'Server Baseline'. The GUID, links, permissions and settings of the GPO
        are kept. When neither GPO exists, 'Server Baseline' is created.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPO ServerBaseline {
            Name         = 'Server Baseline'
            PreviousName = 'Old Server Policy'
        }
    }
}
