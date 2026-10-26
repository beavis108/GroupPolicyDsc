<#
    .SYNOPSIS
        Tests whether a distinguished name refers to an Active Directory site.

    .DESCRIPTION
        GPOs can be linked to sites, domains and organizational units.
        Get-GPInheritance only supports domains and organizational units, so the
        links of a site are read from the attribute 'gPLink' instead.

    .PARAMETER Target
        The distinguished name of the container.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-GPDscSiteTarget -Target 'CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=contoso,DC=com'
#>
function Test-GPDscSiteTarget
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Target
    )

    return $Target -match '^CN=[^,]+,CN=Sites,CN=Configuration,'
}
