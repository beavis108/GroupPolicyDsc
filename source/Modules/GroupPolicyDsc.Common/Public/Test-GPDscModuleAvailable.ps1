<#
    .SYNOPSIS
        Tests whether the PowerShell module 'GroupPolicy' is available on the
        local node.

    .DESCRIPTION
        The module 'GroupPolicy' is part of the Group Policy Management Console
        (GPMC). On Windows Server it is installed with the Windows feature 'GPMC',
        on Windows clients with the RSAT capability
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0'.

        The function never throws.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-GPDscModuleAvailable

        Returns $true if the module 'GroupPolicy' can be imported.
#>
function Test-GPDscModuleAvailable
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    if (Get-Module -Name 'GroupPolicy' -ListAvailable -ErrorAction 'SilentlyContinue')
    {
        Write-Verbose -Message $script:localizedData.ModuleAvailable

        return $true
    }

    Write-Verbose -Message $script:localizedData.ModuleNotAvailable

    return $false
}
