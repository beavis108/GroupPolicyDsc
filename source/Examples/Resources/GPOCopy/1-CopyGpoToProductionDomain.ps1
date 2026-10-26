<#
    .DESCRIPTION
        This example shows how to copy a GPO from the test domain to the
        production domain once, using a migration table.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPOCopy ServerBaseline {
            TargetName     = 'Server Baseline'
            TargetDomain   = 'contoso.com'
            SourceName     = 'Server Baseline'
            SourceDomain   = 'test.contoso.com'
            MigrationTable = 'C:\GPO\test-to-prod.migtable'
        }
    }
}
