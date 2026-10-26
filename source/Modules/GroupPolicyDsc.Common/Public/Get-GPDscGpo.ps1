<#
    .SYNOPSIS
        Returns a Group Policy Object by its display name, or $null if it does
        not exist.

    .DESCRIPTION
        Get-GPO throws when the GPO does not exist. This function returns $null
        in that case, so the resources can report the GPO as absent. All other
        errors (for example an unreachable domain) are re-thrown, so a
        connection problem is never mistaken for an absent GPO.

    .PARAMETER Name
        The display name of the GPO.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.

    .OUTPUTS
        Microsoft.GroupPolicy.Gpo

    .EXAMPLE
        Get-GPDscGpo -Name 'Baseline' -Domain 'contoso.com'
#>
function Get-GPDscGpo
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    try
    {
        return Get-GPO -Name $Name @connectionParameters -ErrorAction 'Stop'
    }
    catch
    {
        if ($_.CategoryInfo.Category -eq 'ObjectNotFound' -or $_.FullyQualifiedErrorId -like '*NotFound*')
        {
            return $null
        }

        New-InvalidOperationException -Message ($script:localizedData.GpoQueryFailed -f $Name) -ErrorRecord $_
    }
}
