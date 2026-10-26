<#
    .DESCRIPTION
        This example shows how to block the inheritance of GPOs for two
        organizational units and to make sure it is not blocked for a third
        one.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        foreach ($ou in @('OU=Kiosk,DC=contoso,DC=com', 'OU=Lab,DC=contoso,DC=com'))
        {
            GPInheritance "Block_$($ou.Split(',')[0].Substring(3))" {
                Target    = $ou
                IsBlocked = $true
            }
        }

        GPInheritance Servers {
            Target    = 'OU=Servers,DC=contoso,DC=com'
            IsBlocked = $false
        }
    }
}
