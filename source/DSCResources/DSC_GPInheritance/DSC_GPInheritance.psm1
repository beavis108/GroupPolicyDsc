$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Common Modules
Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'GroupPolicyDsc.Common')
Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    NOTE: The module 'GroupPolicy' must NOT be imported here,
    see Import-GPDscModule in GroupPolicyDsc.Common.
#>

<#
    .SYNOPSIS
        Returns the current inheritance state of the domain or organizational
        unit.

    .PARAMETER Target
        Specifies the distinguished name of the domain or organizational unit.

    .PARAMETER IsBlocked
        Specifies if inheritance should be blocked. Not used in the function.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain.

    .PARAMETER Server
        Specifies the domain controller to contact.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Target,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsBlocked,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Target)

    $getTargetResourceResult = @{
        Target            = $Target
        IsBlocked         = $null
        Domain            = $Domain
        Server            = $Server
        ContainerType     = $null
        GpoLinks          = [System.String[]] @()
        InheritedGpoLinks = [System.String[]] @()
    }

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $getTargetResourceResult
    }

    Import-GPDscModule

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    try
    {
        $inheritance = Get-GPInheritance -Target $Target @connectionParameters -ErrorAction 'Stop'
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.GetInheritanceFailed -f $Target) -ErrorRecord $_
    }

    $getTargetResourceResult.IsBlocked = [System.Boolean] $inheritance.GpoInheritanceBlocked
    $getTargetResourceResult.ContainerType = [System.String] $inheritance.ContainerType
    $getTargetResourceResult.GpoLinks = [System.String[]] @($inheritance.GpoLinks | ForEach-Object -Process { [System.String] $_.DisplayName })
    $getTargetResourceResult.InheritedGpoLinks = [System.String[]] @($inheritance.InheritedGpoLinks | ForEach-Object -Process { [System.String] $_.DisplayName })

    Write-Verbose -Message ($script:localizedData.InheritanceFound -f $Target, $getTargetResourceResult.IsBlocked)

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Blocks or unblocks inheritance for the domain or organizational unit.

    .PARAMETER Target
        Specifies the distinguished name of the domain or organizational unit.

    .PARAMETER IsBlocked
        Specifies if inheritance should be blocked.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain.

    .PARAMETER Server
        Specifies the domain controller to contact.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Target,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsBlocked,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    if (-not (Assert-GPDscModule))
    {
        return
    }

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    Write-Verbose -Message ($script:localizedData.SettingInheritance -f $Target, $IsBlocked)

    try
    {
        $null = Set-GPInheritance -Target $Target -IsBlocked (ConvertTo-GPDscYesNo -Value $IsBlocked) @connectionParameters -Confirm:$false -ErrorAction 'Stop'
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.SetInheritanceFailed -f $Target) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the inheritance of the domain or organizational unit is
        in the desired state.

    .PARAMETER Target
        Specifies the distinguished name of the domain or organizational unit.

    .PARAMETER IsBlocked
        Specifies if inheritance should be blocked.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain.

    .PARAMETER Server
        Specifies the domain controller to contact.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Target,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsBlocked,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Target)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource @PSBoundParameters

    if ($currentState.IsBlocked -eq $IsBlocked)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Target)

        return $true
    }

    Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Target, $IsBlocked, $currentState.IsBlocked)

    return $false
}

Export-ModuleMember -Function *-TargetResource
