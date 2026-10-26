#region HEADER
# Integration test configuration for DSC_GPStarterGPO. Dot-sourced by DSC_GPStarterGPO.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName       = 'localhost'
            DomainName     = $integrationSetting.DomainName
            StarterGpoName = 'GPDscIT Starter'
            GpoName        = 'GPDscIT From Starter'
        }
    )
}

<#
    .SYNOPSIS
        Creates a Starter GPO and a GPO from it.
#>
configuration DSC_GPStarterGPO_Create_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPStarterGPO 'Integration_Test'
        {
            Name    = $Node.StarterGpoName
            Domain  = $Node.DomainName
            Comment = 'GroupPolicyDsc integration test'
        }

        GPO 'Integration_Test_FromStarter'
        {
            Name           = $Node.GpoName
            Domain         = $Node.DomainName
            StarterGpoName = $Node.StarterGpoName
            DependsOn      = '[GPStarterGPO]Integration_Test'
        }
    }
}
