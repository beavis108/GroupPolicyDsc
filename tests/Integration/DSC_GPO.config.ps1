#region HEADER
# Integration test configuration for DSC_GPO. Dot-sourced by DSC_GPO.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName       = 'localhost'
            DomainName     = $integrationSetting.DomainName
            GpoName        = 'GPDscIT GPO'
            RenamedGpoName = 'GPDscIT GPO Renamed'
            Comment        = 'GroupPolicyDsc integration test'
        }
    )
}

<#
    .SYNOPSIS
        Creates a GPO with comment and status.
#>
configuration DSC_GPO_Create_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPO 'Integration_Test'
        {
            Name    = $Node.GpoName
            Domain  = $Node.DomainName
            Comment = $Node.Comment
            Status  = 'UserSettingsDisabled'
        }
    }
}

<#
    .SYNOPSIS
        Renames the GPO.
#>
configuration DSC_GPO_Rename_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPO 'Integration_Test'
        {
            Name         = $Node.RenamedGpoName
            PreviousName = $Node.GpoName
            Domain       = $Node.DomainName
            Comment      = $Node.Comment
            Status       = 'UserSettingsDisabled'
        }
    }
}

<#
    .SYNOPSIS
        Removes the GPO.
#>
configuration DSC_GPO_Remove_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPO 'Integration_Test'
        {
            Name   = $Node.RenamedGpoName
            Domain = $Node.DomainName
            Ensure = 'Absent'
        }
    }
}
