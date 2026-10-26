#region HEADER
# Integration test configuration for DSC_GPOImport. Dot-sourced by DSC_GPOImport.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName      = 'localhost'
            DomainName    = $integrationSetting.DomainName
            GpoName       = 'GPDscIT Import'
            SourceGpoName = 'GPDscIT Import Source'
            BackupPath    = Join-Path -Path $integrationSetting.WorkPath -ChildPath 'ImportBackup'
        }
    )
}

<#
    .SYNOPSIS
        Imports the backup into a new GPO.
#>
configuration DSC_GPOImport_Once_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPOImport 'Integration_Test'
        {
            Name          = $Node.GpoName
            Domain        = $Node.DomainName
            Path          = $Node.BackupPath
            BackupGpoName = $Node.SourceGpoName
            Mode          = 'Once'
        }
    }
}

<#
    .SYNOPSIS
        Keeps the GPO in line with the backup.
#>
configuration DSC_GPOImport_Enforce_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPOImport 'Integration_Test'
        {
            Name          = $Node.GpoName
            Domain        = $Node.DomainName
            Path          = $Node.BackupPath
            BackupGpoName = $Node.SourceGpoName
            Mode          = 'Enforce'
        }
    }
}
