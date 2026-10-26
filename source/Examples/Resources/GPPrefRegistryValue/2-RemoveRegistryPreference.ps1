<#
    .DESCRIPTION
        This example shows how to delete a value on the clients with a
        preference item, and how to remove a preference item from the GPO.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPPrefRegistryValue DeleteOldServer {
            Name      = 'Client Settings'
            Context   = 'Computer'
            Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso\Agent'
            ValueName = 'OldServer'
            Action    = 'Delete'
        }

        GPPrefRegistryValue RemoveItem {
            Name      = 'Client Settings'
            Context   = 'User'
            Key       = 'HKEY_CURRENT_USER\SOFTWARE\Contoso\Portal'
            ValueName = 'Theme'
            Ensure    = 'Absent'
        }
    }
}
