<#
    .DESCRIPTION
        This example shows how to configure registry-based policy settings of
        different types in the computer and in the user configuration of a
        GPO.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        # Computer Configuration > Administrative Templates > Windows Components > AutoPlay Policies > Turn off Autoplay
        GPRegistryValue NoDriveTypeAutoRun {
            Name      = 'Server Baseline'
            Key       = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
            ValueName = 'NoDriveTypeAutoRun'
            Type      = 'DWord'
            Value     = '0xFF'
        }

        # Computer Configuration > Administrative Templates > Network > DNS Client > DNS Suffix Search List
        GPRegistryValue DnsSearchList {
            Name      = 'Server Baseline'
            Key       = 'HKLM\Software\Policies\Microsoft\Windows NT\DNSClient'
            ValueName = 'SearchList'
            Type      = 'String'
            Value     = 'contoso.com,corp.contoso.com'
        }

        # User Configuration > Administrative Templates > Control Panel > Personalization > Screen saver timeout
        GPRegistryValue ScreenSaveTimeOut {
            Name      = 'Server Baseline'
            Key       = 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
            ValueName = 'ScreenSaveTimeOut'
            Type      = 'String'
            Value     = '900'
        }
    }
}
