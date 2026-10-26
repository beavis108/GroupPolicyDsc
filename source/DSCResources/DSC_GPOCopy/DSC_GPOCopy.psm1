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
        Returns whether the copy of the Group Policy Object exists.

    .PARAMETER TargetName
        Specifies the display name of the new GPO.

    .PARAMETER SourceName
        Specifies the display name of the GPO that is copied.

    .PARAMETER SourceDomain
        Specifies the domain of the source GPO.

    .PARAMETER TargetDomain
        Specifies the domain of the new GPO.

    .PARAMETER SourceServer
        Specifies the domain controller of the source domain.

    .PARAMETER TargetServer
        Specifies the domain controller of the target domain.
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
        $TargetName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourceName,

        [Parameter()]
        [System.String]
        $SourceDomain,

        [Parameter()]
        [System.String]
        $TargetDomain,

        [Parameter()]
        [System.String]
        $SourceServer,

        [Parameter()]
        [System.String]
        $TargetServer
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $TargetName, $SourceName)

    $getTargetResourceResult = @{
        TargetName     = $TargetName
        SourceName     = $SourceName
        SourceDomain   = $SourceDomain
        TargetDomain   = $TargetDomain
        SourceServer   = $SourceServer
        TargetServer   = $TargetServer
        MigrationTable = $null
        CopyAcl        = $null
        TargetGpoId    = $null
        SourceGpoId    = $null
    }

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $getTargetResourceResult
    }

    Import-GPDscModule

    $targetGpo = Get-GPDscGpo -Name $TargetName -Domain $TargetDomain -Server $TargetServer

    if ($null -eq $targetGpo)
    {
        Write-Verbose -Message ($script:localizedData.TargetNotFound -f $TargetName)
    }
    else
    {
        $getTargetResourceResult.TargetGpoId = [System.String] $targetGpo.Id

        Write-Verbose -Message ($script:localizedData.TargetFound -f $TargetName, $getTargetResourceResult.TargetGpoId)
    }

    $sourceGpo = Get-GPDscGpo -Name $SourceName -Domain $SourceDomain -Server $SourceServer

    if ($null -ne $sourceGpo)
    {
        $getTargetResourceResult.SourceGpoId = [System.String] $sourceGpo.Id
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Copies the Group Policy Object.

    .PARAMETER TargetName
        Specifies the display name of the new GPO.

    .PARAMETER SourceName
        Specifies the display name of the GPO that is copied.

    .PARAMETER SourceDomain
        Specifies the domain of the source GPO.

    .PARAMETER TargetDomain
        Specifies the domain of the new GPO.

    .PARAMETER SourceServer
        Specifies the domain controller of the source domain.

    .PARAMETER TargetServer
        Specifies the domain controller of the target domain.

    .PARAMETER MigrationTable
        Specifies the path of a migration table file.

    .PARAMETER CopyAcl
        Specifies if the permissions of the source GPO are copied.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourceName,

        [Parameter()]
        [System.String]
        $SourceDomain,

        [Parameter()]
        [System.String]
        $TargetDomain,

        [Parameter()]
        [System.String]
        $SourceServer,

        [Parameter()]
        [System.String]
        $TargetServer,

        [Parameter()]
        [System.String]
        $MigrationTable,

        [Parameter()]
        [System.Boolean]
        $CopyAcl = $false
    )

    if (-not [System.String]::IsNullOrEmpty($MigrationTable) -and -not (Test-Path -LiteralPath $MigrationTable -PathType 'Leaf'))
    {
        New-InvalidOperationException -Message ($script:localizedData.MigrationTableNotFound -f $MigrationTable)
    }

    if (-not (Assert-GPDscModule))
    {
        return
    }

    if ($null -ne (Get-GPDscGpo -Name $TargetName -Domain $TargetDomain -Server $TargetServer))
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $TargetName)

        return
    }

    $sourceGpo = Get-GPDscGpo -Name $SourceName -Domain $SourceDomain -Server $SourceServer

    if ($null -eq $sourceGpo)
    {
        New-InvalidOperationException -Message ($script:localizedData.SourceNotFound -f $SourceName)
    }

    $copyParameters = @{
        SourceGuid  = $sourceGpo.Id
        TargetName  = $TargetName
        Confirm     = $false
        ErrorAction = 'Stop'
    }

    $optionalParameters = @{
        SourceDomain           = $SourceDomain
        TargetDomain           = $TargetDomain
        SourceDomainController = $SourceServer
        TargetDomainController = $TargetServer
        MigrationTable         = $MigrationTable
    }

    foreach ($parameterName in $optionalParameters.Keys)
    {
        if (-not [System.String]::IsNullOrWhiteSpace($optionalParameters[$parameterName]))
        {
            $copyParameters[$parameterName] = $optionalParameters[$parameterName]
        }
    }

    if ($CopyAcl)
    {
        $copyParameters['CopyAcl'] = $true
    }

    Write-Verbose -Message ($script:localizedData.CopyingGpo -f $SourceName, $TargetName)

    try
    {
        $null = Copy-GPO @copyParameters
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.CopyFailed -f $SourceName, $TargetName) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the copy of the Group Policy Object exists.

    .PARAMETER TargetName
        Specifies the display name of the new GPO.

    .PARAMETER SourceName
        Specifies the display name of the GPO that is copied.

    .PARAMETER SourceDomain
        Specifies the domain of the source GPO.

    .PARAMETER TargetDomain
        Specifies the domain of the new GPO.

    .PARAMETER SourceServer
        Specifies the domain controller of the source domain.

    .PARAMETER TargetServer
        Specifies the domain controller of the target domain.

    .PARAMETER MigrationTable
        Specifies the path of a migration table file.

    .PARAMETER CopyAcl
        Specifies if the permissions of the source GPO are copied.
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
        $TargetName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourceName,

        [Parameter()]
        [System.String]
        $SourceDomain,

        [Parameter()]
        [System.String]
        $TargetDomain,

        [Parameter()]
        [System.String]
        $SourceServer,

        [Parameter()]
        [System.String]
        $TargetServer,

        [Parameter()]
        [System.String]
        $MigrationTable,

        [Parameter()]
        [System.Boolean]
        $CopyAcl = $false
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $TargetName)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    Import-GPDscModule

    if ($null -ne (Get-GPDscGpo -Name $TargetName -Domain $TargetDomain -Server $TargetServer))
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $TargetName)

        return $true
    }

    Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $TargetName)

    return $false
}

Export-ModuleMember -Function *-TargetResource
