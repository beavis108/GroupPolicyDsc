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
        Returns the current state of the imported Group Policy Object.

    .PARAMETER Name
        Specifies the display name of the target GPO.

    .PARAMETER Path
        Specifies the folder that contains the GPO backups.

    .PARAMETER BackupId
        Specifies the ID of the backup to import.

    .PARAMETER BackupGpoName
        Specifies the display name of the backed-up GPO.

    .PARAMETER Mode
        Specifies when the backup is imported.

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
        $BackupId,

        [Parameter()]
        [System.String]
        $BackupGpoName,

        [Parameter()]
        [ValidateSet('Once', 'Enforce')]
        [System.String]
        $Mode = 'Once',

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Name, $Path)

    $backup = Resolve-ImportBackup -Name $Name -Path $Path -BackupId $BackupId -BackupGpoName $BackupGpoName

    $getTargetResourceResult = @{
        Name           = $Name
        Path           = $Path
        BackupId       = $null
        BackupGpoName  = $null
        MigrationTable = $null
        Mode           = $Mode
        Domain         = $Domain
        Server         = $Server
        GpoId          = $null
        HasSettings    = $false
        SettingsMatch  = $null
    }

    if ($null -eq $backup)
    {
        Write-Verbose -Message ($script:localizedData.BackupNotFound -f $Path, $BackupId, (Get-BackupGpoName -Name $Name -BackupGpoName $BackupGpoName))
    }
    else
    {
        $getTargetResourceResult.BackupId = $backup.Id
        $getTargetResourceResult.BackupGpoName = $backup.GpoName

        $backupTimeText = [System.String] $backup.BackupTime

        if ($backup.BackupTime -is [System.DateTime])
        {
            $backupTimeText = $backup.BackupTime.ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
        }

        Write-Verbose -Message ($script:localizedData.BackupFound -f $backup.Id, $backup.GpoName, $backupTimeText)
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
    $getTargetResourceResult.HasSettings = ([System.UInt32] $gpo.Computer.DSVersion -gt 0) -or ([System.UInt32] $gpo.User.DSVersion -gt 0)

    Write-Verbose -Message ($script:localizedData.GpoFound -f $Name, $getTargetResourceResult.HasSettings)

    if ($Mode -eq 'Enforce' -and $null -ne $backup)
    {
        if ([System.String]::IsNullOrEmpty($backup.ReportPath))
        {
            Write-Verbose -Message ($script:localizedData.BackupReportMissing -f $backup.Path)
        }
        else
        {
            $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

            try
            {
                $gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType 'Xml' @connectionParameters -ErrorAction 'Stop'
            }
            catch
            {
                New-InvalidOperationException -Message ($script:localizedData.GetReportFailed -f $Name) -ErrorRecord $_
            }

            $getTargetResourceResult.SettingsMatch = (Get-GPDscReportSetting -ReportXml $gpoReport) -ceq (Get-GPDscReportSetting -Path $backup.ReportPath)

            Write-Verbose -Message ($script:localizedData.SettingsCompared -f $Name, $backup.Id, $getTargetResourceResult.SettingsMatch)
        }
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Imports the GPO backup into the Group Policy Object.

    .PARAMETER Name
        Specifies the display name of the target GPO.

    .PARAMETER Path
        Specifies the folder that contains the GPO backups.

    .PARAMETER BackupId
        Specifies the ID of the backup to import.

    .PARAMETER BackupGpoName
        Specifies the display name of the backed-up GPO.

    .PARAMETER MigrationTable
        Specifies the path of a migration table file.

    .PARAMETER Mode
        Specifies when the backup is imported.

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
        $BackupId,

        [Parameter()]
        [System.String]
        $BackupGpoName,

        [Parameter()]
        [System.String]
        $MigrationTable,

        [Parameter()]
        [ValidateSet('Once', 'Enforce')]
        [System.String]
        $Mode = 'Once',

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    if (-not (Test-Path -LiteralPath $Path -PathType 'Container'))
    {
        New-InvalidOperationException -Message ($script:localizedData.PathNotFound -f $Path)
    }

    $backup = Resolve-ImportBackup -Name $Name -Path $Path -BackupId $BackupId -BackupGpoName $BackupGpoName

    if ($null -eq $backup)
    {
        New-InvalidOperationException -Message ($script:localizedData.BackupNotFound -f $Path, $BackupId, (Get-BackupGpoName -Name $Name -BackupGpoName $BackupGpoName))
    }

    if (-not [System.String]::IsNullOrEmpty($MigrationTable) -and -not (Test-Path -LiteralPath $MigrationTable -PathType 'Leaf'))
    {
        New-InvalidOperationException -Message ($script:localizedData.MigrationTableNotFound -f $MigrationTable)
    }

    if (-not (Assert-GPDscModule))
    {
        return
    }

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    $importParameters = @{
        BackupId       = $backup.Id
        Path           = $Path
        TargetName     = $Name
        CreateIfNeeded = $true
        Confirm        = $false
        ErrorAction    = 'Stop'
    }

    if (-not [System.String]::IsNullOrEmpty($MigrationTable))
    {
        $importParameters['MigrationTable'] = $MigrationTable
    }

    Write-Verbose -Message ($script:localizedData.ImportingBackup -f $backup.Id, $backup.GpoName, $Name)

    try
    {
        $null = Import-GPO @importParameters @connectionParameters
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ImportFailed -f $backup.Id, $Name) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the Group Policy Object contains the settings of the GPO
        backup.

    .PARAMETER Name
        Specifies the display name of the target GPO.

    .PARAMETER Path
        Specifies the folder that contains the GPO backups.

    .PARAMETER BackupId
        Specifies the ID of the backup to import.

    .PARAMETER BackupGpoName
        Specifies the display name of the backed-up GPO.

    .PARAMETER MigrationTable
        Specifies the path of a migration table file.

    .PARAMETER Mode
        Specifies when the backup is imported.

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
        $BackupId,

        [Parameter()]
        [System.String]
        $BackupGpoName,

        [Parameter()]
        [System.String]
        $MigrationTable,

        [Parameter()]
        [ValidateSet('Once', 'Enforce')]
        [System.String]
        $Mode = 'Once',

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Name, $Mode)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -Path $Path -BackupId $BackupId -BackupGpoName $BackupGpoName -Mode $Mode -Domain $Domain -Server $Server

    $inDesiredState = $false

    if ($null -eq $currentState.GpoId)
    {
        Write-Verbose -Message ($script:localizedData.GpoMissing -f $Name)
    }
    elseif ($Mode -eq 'Once')
    {
        $inDesiredState = $currentState.HasSettings

        if (-not $inDesiredState)
        {
            Write-Verbose -Message ($script:localizedData.GpoEmpty -f $Name)
        }
    }
    elseif ($null -eq $currentState.BackupId)
    {
        Write-Verbose -Message ($script:localizedData.BackupMissingForCompare -f $Name)
    }
    else
    {
        $inDesiredState = $currentState.SettingsMatch -eq $true

        if (-not $inDesiredState)
        {
            Write-Verbose -Message ($script:localizedData.SettingsDiffer -f $Name, $currentState.BackupId)
        }
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Name)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Name)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Returns the display name of the backed-up GPO that is searched for.

    .PARAMETER Name
        The display name of the target GPO.

    .PARAMETER BackupGpoName
        The configured display name of the backed-up GPO.
#>
function Get-BackupGpoName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $BackupGpoName
    )

    if ([System.String]::IsNullOrWhiteSpace($BackupGpoName))
    {
        return $Name
    }

    return $BackupGpoName
}

<#
    .SYNOPSIS
        Returns the backup to import, or $null.

    .DESCRIPTION
        When BackupId is specified, that backup is returned. Otherwise the most
        recent backup of the GPO BackupGpoName (defaults to Name) is returned,
        which is the same backup Import-GPO -BackupGpoName would use.

    .PARAMETER Name
        The display name of the target GPO.

    .PARAMETER Path
        The folder that contains the GPO backups.

    .PARAMETER BackupId
        The ID of the backup.

    .PARAMETER BackupGpoName
        The display name of the backed-up GPO.
#>
function Resolve-ImportBackup
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $BackupId,

        [Parameter()]
        [System.String]
        $BackupGpoName
    )

    if (-not [System.String]::IsNullOrWhiteSpace($BackupId))
    {
        return Get-GPDscBackup -Path $Path -BackupId $BackupId | Select-Object -First 1
    }

    return Get-GPDscBackup -Path $Path -GpoName (Get-BackupGpoName -Name $Name -BackupGpoName $BackupGpoName) | Select-Object -First 1
}

Export-ModuleMember -Function *-TargetResource
