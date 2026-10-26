#region HEADER
# Integration test configuration for DSC_GPLink. Dot-sourced by DSC_GPLink.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName      = 'localhost'
            DomainName    = $integrationSetting.DomainName
            GpoName       = 'GPDscIT Link'
            SecondGpoName = 'GPDscIT Link 2'
            OuDN          = $integrationSetting.OuDN
            SiteDN        = $integrationSetting.SiteDN
        }
    )
}

<#
    .SYNOPSIS
        Links the GPO to the test OU and enforces the link.
#>
configuration DSC_GPLink_Create_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPLink 'Integration_Test'
        {
            Name     = $Node.GpoName
            Target   = $Node.OuDN
            Domain   = $Node.DomainName
            Enforced = $true
        }
    }
}

<#
    .SYNOPSIS
        Disables the link and removes the enforcement.
#>
configuration DSC_GPLink_Change_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPLink 'Integration_Test'
        {
            Name        = $Node.GpoName
            Target      = $Node.OuDN
            Domain      = $Node.DomainName
            LinkEnabled = $false
            Enforced    = $false
        }
    }
}

<#
    .SYNOPSIS
        Links two GPOs to the site of the domain controller.
#>
configuration DSC_GPLink_Site_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPLink 'Integration_Test_Site'
        {
            Name     = $Node.GpoName
            Target   = $Node.SiteDN
            Domain   = $Node.DomainName
            Enforced = $true
        }

        GPLink 'Integration_Test_Site2'
        {
            Name      = $Node.SecondGpoName
            Target    = $Node.SiteDN
            Domain    = $Node.DomainName
            DependsOn = '[GPLink]Integration_Test_Site'
        }
    }
}

<#
    .SYNOPSIS
        Removes all links.
#>
configuration DSC_GPLink_Remove_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPLink 'Integration_Test'
        {
            Name   = $Node.GpoName
            Target = $Node.OuDN
            Domain = $Node.DomainName
            Ensure = 'Absent'
        }

        GPLink 'Integration_Test_Site'
        {
            Name   = $Node.GpoName
            Target = $Node.SiteDN
            Domain = $Node.DomainName
            Ensure = 'Absent'
        }

        GPLink 'Integration_Test_Site2'
        {
            Name   = $Node.SecondGpoName
            Target = $Node.SiteDN
            Domain = $Node.DomainName
            Ensure = 'Absent'
        }
    }
}
