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
        Returns the current state of the Starter GPO.

    .PARAMETER Name
        Specifies the display name of the Starter GPO.

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
        $Name,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Name)

    $getTargetResourceResult = @{
        Name    = $Name
        Comment = $null
        Domain  = $Domain
        Server  = $Server
        Id      = $null
    }

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $getTargetResourceResult
    }

    Import-GPDscModule

    $starterGpo = Get-GPDscStarterGpo -Name $Name -Domain $Domain -Server $Server

    if ($null -eq $starterGpo)
    {
        Write-Verbose -Message ($script:localizedData.StarterGpoNotFound -f $Name)
    }
    else
    {
        $getTargetResourceResult.Id = [System.String] $starterGpo.Id
        $getTargetResourceResult.Comment = [System.String] $starterGpo.Description

        Write-Verbose -Message ($script:localizedData.StarterGpoFound -f $Name, $getTargetResourceResult.Id)
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Creates the Starter GPO.

    .PARAMETER Name
        Specifies the display name of the Starter GPO.

    .PARAMETER Comment
        Specifies the comment of the Starter GPO.

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
        $Name,

        [Parameter()]
        [System.String]
        $Comment,

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

    if ($null -ne (Get-GPDscStarterGpo -Name $Name -Domain $Domain -Server $Server))
    {
        return
    }

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    $newStarterGpoParameters = @{
        Name        = $Name
        Confirm     = $false
        ErrorAction = 'Stop'
    }

    if (-not [System.String]::IsNullOrEmpty($Comment))
    {
        $newStarterGpoParameters['Comment'] = $Comment
    }

    Write-Verbose -Message ($script:localizedData.CreatingStarterGpo -f $Name)

    try
    {
        $null = New-GPStarterGPO @newStarterGpoParameters @connectionParameters
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.CreateStarterGpoFailed -f $Name) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the Starter GPO exists.

    .PARAMETER Name
        Specifies the display name of the Starter GPO.

    .PARAMETER Comment
        Specifies the comment of the Starter GPO.

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
        $Name,

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Name)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -Domain $Domain -Server $Server

    if ($null -ne $currentState.Id)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Name)

        return $true
    }

    Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Name)

    return $false
}

Export-ModuleMember -Function *-TargetResource
