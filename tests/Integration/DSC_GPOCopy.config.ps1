#region HEADER
# Integration test configuration for DSC_GPOCopy. Dot-sourced by DSC_GPOCopy.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName      = 'localhost'
            DomainName    = $integrationSetting.DomainName
            GpoName       = 'GPDscIT Copy'
            SourceGpoName = 'GPDscIT Copy Source'
        }
    )
}

<#
    .SYNOPSIS
        Copies the GPO.
#>
configuration DSC_GPOCopy_Copy_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPOCopy 'Integration_Test'
        {
            TargetName   = $Node.GpoName
            TargetDomain = $Node.DomainName
            SourceName   = $Node.SourceGpoName
            SourceDomain = $Node.DomainName
        }
    }
}
