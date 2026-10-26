<#
    .SYNOPSIS
        Returns the GPO links of a site, domain or organizational unit.

    .DESCRIPTION
        For domains and organizational units the links are read with
        Get-GPInheritance. For sites, which Get-GPInheritance does not support,
        the attribute 'gPLink' is read and parsed.

        The objects returned have the same shape for all container types.

    .PARAMETER Target
        The distinguished name of the site, domain or organizational unit.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]

        Objects with the properties GpoId, DisplayName, Enabled, Enforced and
        Order.

    .EXAMPLE
        Get-GPDscGpoLink -Target 'OU=Servers,DC=contoso,DC=com'
#>
function Get-GPDscGpoLink
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
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

    if (Test-GPDscSiteTarget -Target $Target)
    {
        $gpLink = Get-GPDscSiteGpLink -Target $Target -Domain $Domain -Server $Server

        return @(ConvertFrom-GPDscGpLink -GpLink $gpLink)
    }

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    try
    {
        $inheritance = Get-GPInheritance -Target $Target @connectionParameters -ErrorAction 'Stop'
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.TargetQueryFailed -f $Target) -ErrorRecord $_
    }

    $links = foreach ($gpoLink in $inheritance.GpoLinks)
    {
        [PSCustomObject] @{
            GpoId       = [System.Guid] $gpoLink.GpoId
            DisplayName = [System.String] $gpoLink.DisplayName
            Enabled     = [System.Boolean] $gpoLink.Enabled
            Enforced    = [System.Boolean] $gpoLink.Enforced
            Order       = [System.Int32] $gpoLink.Order
        }
    }

    return @($links)
}
