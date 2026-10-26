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
        Returns the most recent backup of the Group Policy Object and whether
        it is current.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Path
        Specifies the backup folder.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain of the GPO.

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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Name, $Path)

    $getTargetResourceResult = @{
        Name             = $Name
        Path             = $Path
        Comment          = $null
        Domain           = $Domain
        Server           = $Server
        GpoId            = $null
        LatestBackupId   = $null
        LatestBackupTime = $null
        BackupCurrent    = $false
    }

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $getTargetResourceResult
    }

    Import-GPDscModule

    $gpo = Get-GPDscGpo -Name $Name -Domain $Domain -Server $Server

    if ($null -eq $gpo)
    {
        Write-Verbose -Message ($script:localizedData.GpoNotFound -f $Name)

        return $getTargetResourceResult
    }

    $getTargetResourceResult.GpoId = [System.String] $gpo.Id

    $latestBackup = Get-GPDscBackup -Path $Path -GpoId ([System.String] $gpo.Id) | Select-Object -First 1

    if ($null -eq $latestBackup)
    {
        Write-Verbose -Message ($script:localizedData.NoBackupFound -f $Name, $Path)

        return $getTargetResourceResult
    }

    $getTargetResourceResult.LatestBackupId = $latestBackup.Id
    $getTargetResourceResult.Comment = $latestBackup.Comment

    if ($null -ne $latestBackup.BackupTime)
    {
        $getTargetResourceResult.LatestBackupTime = $latestBackup.BackupTime.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $getTargetResourceResult.BackupCurrent = Test-BackupCurrent -Gpo $gpo -Backup $latestBackup

    Write-Verbose -Message ($script:localizedData.BackupFound -f $Name, $latestBackup.Id, $getTargetResourceResult.LatestBackupTime, $getTargetResourceResult.BackupCurrent)

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Backs up the Group Policy Object.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Path
        Specifies the backup folder.

    .PARAMETER Comment
        Specifies the comment of the backup.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain of the GPO.

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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

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

    $gpo = Get-GPDscGpo -Name $Name -Domain $Domain -Server $Server

    if ($null -eq $gpo)
    {
        New-InvalidOperationException -Message ($script:localizedData.GpoRequired -f $Name)
    }

    if (-not (Test-Path -LiteralPath $Path -PathType 'Container'))
    {
        Write-Verbose -Message ($script:localizedData.CreatingFolder -f $Path)

        $null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'
    }

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    $backupParameters = @{
        Guid        = $gpo.Id
        Path        = $Path
        Confirm     = $false
        ErrorAction = 'Stop'
    }

    if (-not [System.String]::IsNullOrEmpty($Comment))
    {
        $backupParameters['Comment'] = $Comment
    }

    Write-Verbose -Message ($script:localizedData.BackingUpGpo -f $Name, $Path)

    try
    {
        $null = Backup-GPO @backupParameters @connectionParameters
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.BackupFailed -f $Name, $Path) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether a current backup of the Group Policy Object exists.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Path
        Specifies the backup folder.

    .PARAMETER Comment
        Specifies the comment of the backup.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain of the GPO.

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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

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

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Name, $Path)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -Path $Path -Domain $Domain -Server $Server

    if ($currentState.BackupCurrent)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Name, $Path)

        return $true
    }

    Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Name, $Path)

    return $false
}

<#
    .SYNOPSIS
        Tests whether a backup contains the current version of a GPO.

    .DESCRIPTION
        The version numbers of the computer and user configuration (Active
        Directory and SYSVOL) are compared with the versions in the report
        'gpreport.xml' of the backup. Every change of a setting increases these
        numbers. When the backup has no report, the backup time is compared
        with the modification time of the GPO instead.

    .PARAMETER Gpo
        The GPO object.

    .PARAMETER Backup
        The backup object returned by Get-GPDscBackup.
#>
function Test-BackupCurrent
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Gpo,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Backup
    )

    if ($null -ne $Backup.ComputerVersionDirectory -and $null -ne $Backup.UserVersionDirectory)
    {
        return (
            [System.UInt32] $Backup.ComputerVersionDirectory -eq [System.UInt32] $Gpo.Computer.DSVersion -and
            [System.UInt32] $Backup.ComputerVersionSysvol -eq [System.UInt32] $Gpo.Computer.SysvolVersion -and
            [System.UInt32] $Backup.UserVersionDirectory -eq [System.UInt32] $Gpo.User.DSVersion -and
            [System.UInt32] $Backup.UserVersionSysvol -eq [System.UInt32] $Gpo.User.SysvolVersion
        )
    }

    if ($null -eq $Backup.BackupTime -or $null -eq $Gpo.ModificationTime)
    {
        return $false
    }

    return $Backup.BackupTime -ge ([System.DateTime] $Gpo.ModificationTime).ToUniversalTime()
}

Export-ModuleMember -Function *-TargetResource
