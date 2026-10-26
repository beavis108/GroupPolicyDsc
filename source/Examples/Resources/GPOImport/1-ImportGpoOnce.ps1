<#
    .DESCRIPTION
        This example shows how to import the most recent backup of the GPO
        'Server Baseline' from a file share once, using a migration table to
        map the security principals of the source domain. Later changes made
        in GPMC are kept.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPOImport ServerBaseline {
            Name           = 'Server Baseline'
            Path           = '\\fs01.contoso.com\GPOBackup$'
            MigrationTable = '\\fs01.contoso.com\GPOBackup$\contoso.migtable'
            Mode           = 'Once'
        }
    }
}
