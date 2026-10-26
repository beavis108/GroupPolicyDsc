#region HEADER
# Integration test configuration for DSC_GPPrefRegistryValue. Dot-sourced by DSC_GPPrefRegistryValue.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            DomainName = $integrationSetting.DomainName
            GpoName    = 'GPDscIT Preference'
            Key        = 'HKEY_LOCAL_MACHINE\SOFTWARE\GPDscIT'
            UserKey    = 'HKEY_CURRENT_USER\SOFTWARE\GPDscIT'
        }
    )
}

<#
    .SYNOPSIS
        Creates Registry preference items.
#>
configuration DSC_GPPrefRegistryValue_Create_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPPrefRegistryValue 'Integration_Test_String'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Context   = 'Computer'
            Key       = $Node.Key
            ValueName = 'Server'
            Type      = 'String'
            Value     = 'srv01.contoso.com'
        }

        GPPrefRegistryValue 'Integration_Test_DWord'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Context   = 'Computer'
            Key       = $Node.Key
            ValueName = 'Port'
            Action    = 'Replace'
            Type      = 'DWord'
            Value     = '443'
            Disabled  = $true
        }

        GPPrefRegistryValue 'Integration_Test_User'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Context   = 'User'
            Key       = $Node.UserKey
            ValueName = 'Ports'
            Type      = 'MultiString'
            Value     = '443', '8443'
        }
    }
}

<#
    .SYNOPSIS
        Changes the value of a Registry preference item.
#>
configuration DSC_GPPrefRegistryValue_Change_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPPrefRegistryValue 'Integration_Test_String'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Context   = 'Computer'
            Key       = $Node.Key
            ValueName = 'Server'
            Type      = 'String'
            Value     = 'srv02.contoso.com'
        }
    }
}

<#
    .SYNOPSIS
        Removes a Registry preference item.
#>
configuration DSC_GPPrefRegistryValue_Remove_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPPrefRegistryValue 'Integration_Test_String'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Context   = 'Computer'
            Key       = $Node.Key
            ValueName = 'Server'
            Ensure    = 'Absent'
        }
    }
}
