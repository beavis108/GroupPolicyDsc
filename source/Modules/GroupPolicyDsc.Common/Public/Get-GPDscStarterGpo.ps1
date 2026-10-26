<#
    .SYNOPSIS
        Returns a Starter GPO by its display name, or $null if it does not
        exist.

    .DESCRIPTION
        Get-GPStarterGPO throws when the Starter GPO does not exist. This
        function returns $null in that case. All other errors are re-thrown.

    .PARAMETER Name
        The display name of the Starter GPO.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.

    .OUTPUTS
        Microsoft.GroupPolicy.StarterGpo

    .EXAMPLE
        Get-GPDscStarterGpo -Name 'Baseline Template'
#>
function Get-GPDscStarterGpo
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
        return Get-GPStarterGPO -Name $Name @connectionParameters -ErrorAction 'Stop'
    }
    catch
    {
        if ($_.CategoryInfo.Category -eq 'ObjectNotFound' -or $_.FullyQualifiedErrorId -like '*NotFound*')
        {
            return $null
        }

        New-InvalidOperationException -Message ($script:localizedData.StarterGpoQueryFailed -f $Name) -ErrorRecord $_
    }
}
