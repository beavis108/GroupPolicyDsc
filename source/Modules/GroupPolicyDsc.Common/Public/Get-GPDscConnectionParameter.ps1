<#
    .SYNOPSIS
        Returns the connection parameters (domain and domain controller) for the
        cmdlets of the module 'GroupPolicy'.

    .DESCRIPTION
        Builds a hashtable that can be splatted to the GroupPolicy cmdlets. Empty
        values are left out, so the cmdlets use their defaults (the domain of the
        account that runs the LCM and the PDC emulator).

        Most cmdlets name the domain parameter 'Domain', Get-GPPermission and
        Set-GPPermission name it 'DomainName'.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.

    .PARAMETER DomainParameterName
        The name of the domain parameter of the cmdlet. Defaults to 'Domain'.

    .OUTPUTS
        System.Collections.Hashtable

    .EXAMPLE
        $connection = Get-GPDscConnectionParameter -Domain 'contoso.com' -Server 'dc01'
        Get-GPO -Name 'Baseline' @connection
#>
function Get-GPDscConnectionParameter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [ValidateSet('Domain', 'DomainName')]
        [System.String]
        $DomainParameterName = 'Domain'
    )

    $connectionParameters = @{}

    if (-not [System.String]::IsNullOrWhiteSpace($Domain))
    {
        $connectionParameters[$DomainParameterName] = $Domain
    }

    if (-not [System.String]::IsNullOrWhiteSpace($Server))
    {
        $connectionParameters['Server'] = $Server
    }

    return $connectionParameters
}
