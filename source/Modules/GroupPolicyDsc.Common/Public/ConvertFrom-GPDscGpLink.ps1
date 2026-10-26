<#
    .SYNOPSIS
        Converts the value of the Active Directory attribute 'gPLink' to GPO link
        objects.

    .DESCRIPTION
        The attribute 'gPLink' of a site, domain or organizational unit contains
        one entry per linked GPO in the format
        '[LDAP://cn={GUID},cn=policies,cn=system,DC=contoso,DC=com;<options>]'.

        The options are a bit field: 1 = the link is disabled, 2 = the link is
        enforced. The first entry has the highest link order (lowest
        precedence), the last entry has the link order 1.

    .PARAMETER GpLink
        The value of the attribute 'gPLink'.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]

        Objects with the properties GpoId, DisplayName, Enabled, Enforced and
        Order.

    .EXAMPLE
        ConvertFrom-GPDscGpLink -GpLink '[LDAP://cn={31B2F340-016D-11D2-945F-00C04FB984F9},cn=policies,cn=system,DC=contoso,DC=com;0]'
#>
function ConvertFrom-GPDscGpLink
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $GpLink
    )

    if ([System.String]::IsNullOrWhiteSpace($GpLink))
    {
        return @()
    }

    $linkMatches = [System.Text.RegularExpressions.Regex]::Matches(
        $GpLink,
        '\[LDAP://cn=\{(?<guid>[0-9a-f\-]{36})\}[^;\]]*;(?<options>\d+)\]',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    $linkCount = $linkMatches.Count
    $index = 0

    $links = foreach ($linkMatch in $linkMatches)
    {
        $options = [System.Int32] $linkMatch.Groups['options'].Value

        [PSCustomObject] @{
            GpoId       = [System.Guid] $linkMatch.Groups['guid'].Value
            DisplayName = $null
            Enabled     = -not ($options -band 1)
            Enforced    = [System.Boolean] ($options -band 2)
            Order       = [System.Int32] ($linkCount - $index)
        }

        $index++
    }

    return @($links)
}
