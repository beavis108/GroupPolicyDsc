#region HEADER
# Integration test configuration for DSC_GPOBackup. Dot-sourced by DSC_GPOBackup.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            DomainName = $integrationSetting.DomainName
            GpoName    = 'GPDscIT Backup'
            BackupPath = Join-Path -Path $integrationSetting.WorkPath -ChildPath 'Backup'
        }
    )
}

<#
    .SYNOPSIS
        Keeps a current backup of the GPO.
#>
configuration DSC_GPOBackup_Backup_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPOBackup 'Integration_Test'
        {
            Name    = $Node.GpoName
            Domain  = $Node.DomainName
            Path    = $Node.BackupPath
            Comment = 'GroupPolicyDsc integration test'
        }
    }
}
