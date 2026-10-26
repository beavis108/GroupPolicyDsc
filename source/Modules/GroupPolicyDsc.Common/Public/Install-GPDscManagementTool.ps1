<#
    .SYNOPSIS
        Installs the Group Policy Management Console (Windows feature 'GPMC').

    .DESCRIPTION
        Installs the Windows feature 'GPMC', which contains the PowerShell module
        'GroupPolicy' used by all GroupPolicyDsc resources. The feature can only
        be installed automatically on Windows Server. On Windows clients the RSAT
        capability 'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0' must be
        installed in advance.

        When the installation requires a restart, the DSC engine is told to
        restart the node (Set-DscMachineRebootRequired).

    .OUTPUTS
        System.Boolean

        Returns $true if a restart is required to complete the installation,
        otherwise $false.

    .EXAMPLE
        $restartRequired = Install-GPDscManagementTool

        Installs GPMC and returns whether a restart is pending.
#>
function Install-GPDscManagementTool
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    if (-not (Get-Command -Name 'Install-WindowsFeature' -ErrorAction 'SilentlyContinue'))
    {
        New-InvalidOperationException -Message (
            '{0} {1}' -f $script:localizedData.FeatureCmdletNotAvailable, $script:localizedData.ModuleNotAvailable
        )
    }

    Write-Verbose -Message $script:localizedData.InstallingFeature

    $installResult = Install-WindowsFeature -Name 'GPMC' -ErrorAction 'Stop'

    if (-not $installResult.Success)
    {
        New-InvalidOperationException -Message ($script:localizedData.InstallFeatureFailed -f $installResult.ExitCode)
    }

    $restartRequired = [System.String] $installResult.RestartNeeded -eq 'Yes'

    if ($restartRequired)
    {
        Write-Warning -Message $script:localizedData.InstallFeatureRestartRequired

        Set-DscMachineRebootRequired
    }

    return $restartRequired
}
