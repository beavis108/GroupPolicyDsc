<#
    .SYNOPSIS
        Makes sure the PowerShell module 'GroupPolicy' is installed and imported.

    .DESCRIPTION
        Used by Set-TargetResource of every resource. When the module is missing
        and the node runs Windows Server, the Windows feature 'GPMC' is
        installed. Afterwards the module is imported into the global scope.

        When the installation requires a restart, the function returns $false and
        the DSC engine has been told to restart the node. The caller must stop
        and let the LCM continue after the restart.

    .OUTPUTS
        System.Boolean

        Returns $true when the module is ready to be used.

    .EXAMPLE
        if (-not (Assert-GPDscModule)) { return }
#>
function Assert-GPDscModule
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    if (-not (Test-GPDscModuleAvailable))
    {
        if (Install-GPDscManagementTool)
        {
            return $false
        }
    }

    Import-GPDscModule

    return $true
}
