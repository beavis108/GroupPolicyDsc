#region HEADER
# Integration test configuration for DSC_GPRegistryValue. Dot-sourced by DSC_GPRegistryValue.Integration.Tests.ps1.
# All objects created by the test start with 'GPDscIT', see GroupPolicyDsc.IntegrationHelper.psm1.
#endregion

$integrationSetting = Get-GPDscIntegrationSetting

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            DomainName = $integrationSetting.DomainName
            GpoName    = 'GPDscIT Registry'
            Key        = 'HKLM\Software\Policies\GPDscIT'
            UserKey    = 'HKCU\Software\Policies\GPDscIT'
        }
    )
}

<#
    .SYNOPSIS
        Configures values of every registry value type.
#>
configuration DSC_GPRegistryValue_Set_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPRegistryValue 'Integration_Test_DWord'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = 'DWordValue'
            Type      = 'DWord'
            Value     = '0xFFFFFFFF'
        }

        GPRegistryValue 'Integration_Test_QWord'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = 'QWordValue'
            Type      = 'QWord'
            Value     = '0x100000000'
        }

        GPRegistryValue 'Integration_Test_String'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = 'StringValue'
            Type      = 'String'
            Value     = 'Contoso'
        }

        GPRegistryValue 'Integration_Test_ExpandString'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = 'ExpandStringValue'
            Type      = 'ExpandString'
            Value     = '%SystemRoot%\Temp'
        }

        GPRegistryValue 'Integration_Test_MultiString'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = 'MultiStringValue'
            Type      = 'MultiString'
            Value     = 'a', 'b', 'c'
        }

        GPRegistryValue 'Integration_Test_Binary'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = 'BinaryValue'
            Type      = 'Binary'
            Value     = '01 ff 0a'
        }

        GPRegistryValue 'Integration_Test_Default'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = '(Default)'
            Type      = 'String'
            Value     = 'DefaultValue'
        }

        GPRegistryValue 'Integration_Test_User'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.UserKey
            ValueName = 'UserValue'
            Type      = 'String'
            Value     = 'User'
        }
    }
}

<#
    .SYNOPSIS
        Configures a value to be deleted on the clients and removes another one.
#>
configuration DSC_GPRegistryValue_DeleteAndRemove_Config
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node $AllNodes.NodeName
    {
        GPRegistryValue 'Integration_Test_DWord'
        {
            Name        = $Node.GpoName
            Domain      = $Node.DomainName
            Key         = $Node.Key
            ValueName   = 'DWordValue'
            PolicyState = 'Delete'
        }

        GPRegistryValue 'Integration_Test_String'
        {
            Name      = $Node.GpoName
            Domain    = $Node.DomainName
            Key       = $Node.Key
            ValueName = 'StringValue'
            Ensure    = 'Absent'
        }
    }
}
