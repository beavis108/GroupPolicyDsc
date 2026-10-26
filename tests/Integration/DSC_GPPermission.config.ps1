#region HEADER
# Integration test configuration for DSC_GPPermission. Dot-sourced by DSC_GPPermission.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            DomainName = $integrationSetting.DomainName
            GpoName    = 'GPDscIT Permission'
        }
    )
}

<#
    .SYNOPSIS
        Configures security filtering for Domain Computers.
#>
configuration DSC_GPPermission_SecurityFiltering_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPPermission 'Integration_Test_AuthenticatedUsers'
        {
            Name            = $Node.GpoName
            Domain          = $Node.DomainName
            TargetName      = 'Authenticated Users'
            TargetType      = 'Group'
            PermissionLevel = 'GpoRead'
        }

        GPPermission 'Integration_Test_DomainComputers'
        {
            Name            = $Node.GpoName
            Domain          = $Node.DomainName
            TargetName      = 'Domain Computers'
            TargetType      = 'Group'
            PermissionLevel = 'GpoApply'
        }
    }
}

<#
    .SYNOPSIS
        Removes the permission of Domain Computers.
#>
configuration DSC_GPPermission_Remove_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPPermission 'Integration_Test_DomainComputers'
        {
            Name       = $Node.GpoName
            Domain     = $Node.DomainName
            TargetName = 'Domain Computers'
            TargetType = 'Group'
            Ensure     = 'Absent'
        }
    }
}
