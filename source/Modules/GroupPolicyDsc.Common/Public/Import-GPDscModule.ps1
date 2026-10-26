<#
    .SYNOPSIS
        Imports the PowerShell module 'GroupPolicy' into the global scope.

    .DESCRIPTION
        The DSC resources must not import 'GroupPolicy' when the resource module
        is loaded, because the module does not exist until the Group Policy
        Management Console is installed. xGroupPolicy imported 'ActiveDirectory'
        at load time, which made every resource fail on a node without the
        Active Directory module - although it was never used.

        This function is called lazily by each resource function after the
        module has been verified. The module is imported with -Global so the
        cmdlets are visible to the calling DSC resource also when the LCM runs
        the resource inside wmiprvse.exe.

    .OUTPUTS
        None

    .EXAMPLE
        Import-GPDscModule

        Imports the GroupPolicy module if it is not already imported.
#>
function Import-GPDscModule
{
    [CmdletBinding()]
    [OutputType()]
    param ()

    if (Get-Module -Name 'GroupPolicy')
    {
        return
    }

    if (-not (Get-Module -Name 'GroupPolicy' -ListAvailable))
    {
        New-InvalidOperationException -Message $script:localizedData.ModuleNotAvailable
    }

    Write-Verbose -Message $script:localizedData.ImportingModule

    Import-Module -Name 'GroupPolicy' -Global -Force -ErrorAction 'Stop'
}
