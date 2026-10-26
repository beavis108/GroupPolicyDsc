<#
    .DESCRIPTION
        This example shows how to keep a current backup of two GPOs on a file
        share. A new backup is only created when the settings of a GPO have
        changed since its last backup.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        foreach ($gpoName in @('Default Domain Policy', 'Server Baseline'))
        {
            GPOBackup "Backup_$($gpoName -replace '\W', '')" {
                Name    = $gpoName
                Path    = '\\fs01.contoso.com\GPOBackup$'
                Comment = 'Created by DSC'
            }
        }
    }
}
