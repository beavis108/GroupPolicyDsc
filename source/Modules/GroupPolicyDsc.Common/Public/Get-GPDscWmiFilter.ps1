<#
    .SYNOPSIS
        Returns a WMI filter of a domain by its name, or $null.

    .DESCRIPTION
        The module 'GroupPolicy' has no cmdlet for WMI filters. The filters are
        read through the GPMC API (Microsoft.GroupPolicy.GPDomain), which is
        loaded together with the module 'GroupPolicy'. The returned object can
        be assigned to the property WmiFilter of a GPO.

    .PARAMETER Name
        The name of the WMI filter.

    .PARAMETER Domain
        The fully qualified domain name. Defaults to the domain of the account
        that runs the LCM.

    .PARAMETER Server
        The domain controller to contact. Only used together with Domain.

    .OUTPUTS
        Microsoft.GroupPolicy.WmiFilter

    .EXAMPLE
        $gpo.WmiFilter = Get-GPDscWmiFilter -Name 'Windows Server 2022 or later'
#>
function Get-GPDscWmiFilter
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    try
    {
        if ([System.String]::IsNullOrWhiteSpace($Domain))
        {
            $gpDomain = New-Object -TypeName 'Microsoft.GroupPolicy.GPDomain'
        }
        elseif ([System.String]::IsNullOrWhiteSpace($Server))
        {
            $gpDomain = New-Object -TypeName 'Microsoft.GroupPolicy.GPDomain' -ArgumentList $Domain
        }
        else
        {
            $gpDomain = New-Object -TypeName 'Microsoft.GroupPolicy.GPDomain' -ArgumentList $Domain, $Server
        }

        $searchCriteria = New-Object -TypeName 'Microsoft.GroupPolicy.GPSearchCriteria'

        $wmiFilters = $gpDomain.SearchWmiFilters($searchCriteria)
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.WmiFilterQueryFailed -f $Domain) -ErrorRecord $_
    }

    return $wmiFilters | Where-Object -FilterScript {
        $_.Name -eq $Name
    } | Select-Object -First 1
}
