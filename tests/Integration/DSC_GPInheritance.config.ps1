#region HEADER
# Integration test configuration for DSC_GPInheritance. Dot-sourced by DSC_GPInheritance.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            DomainName = $integrationSetting.DomainName
            OuDN       = $integrationSetting.OuDN
        }
    )
}

<#
    .SYNOPSIS
        Blocks the inheritance of the test OU.
#>
configuration DSC_GPInheritance_Block_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPInheritance 'Integration_Test'
        {
            Target    = $Node.OuDN
            Domain    = $Node.DomainName
            IsBlocked = $true
        }
    }
}

<#
    .SYNOPSIS
        Unblocks the inheritance of the test OU.
#>
configuration DSC_GPInheritance_Unblock_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPInheritance 'Integration_Test'
        {
            Target    = $Node.OuDN
            Domain    = $Node.DomainName
            IsBlocked = $false
        }
    }
}
