<#
    .SYNOPSIS
        Reads the attribute 'gPLink' of an Active Directory container.

    .DESCRIPTION
        Used for sites, because Get-GPInheritance only supports domains and
        organizational units. The container is read through ADSI from the
        domain controller given in Server or, when Server is not specified,
        from a domain controller of the domain given in Domain.

    .PARAMETER Target
        The distinguished name of the container.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-GPDscSiteGpLink -Target 'CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=contoso,DC=com'
#>
function Get-GPDscSiteGpLink
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Target,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    $ldapHost = $Server

    if ([System.String]::IsNullOrWhiteSpace($ldapHost))
    {
        $ldapHost = $Domain
    }

    if ([System.String]::IsNullOrWhiteSpace($ldapHost))
    {
        $ldapPath = 'LDAP://{0}' -f $Target
    }
    else
    {
        $ldapPath = 'LDAP://{0}/{1}' -f $ldapHost, $Target
    }

    try
    {
        $directoryEntry = New-Object -TypeName 'System.DirectoryServices.DirectoryEntry' -ArgumentList $ldapPath

        # Accessing a property binds the object and throws if it does not exist.
        $null = $directoryEntry.Properties['distinguishedName'].Value

        return [System.String] $directoryEntry.Properties['gPLink'].Value
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.TargetQueryFailed -f $Target) -ErrorRecord $_
    }
}
