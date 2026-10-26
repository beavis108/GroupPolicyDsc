<#
    .SYNOPSIS
        Returns the GPO backups in a backup folder.

    .DESCRIPTION
        Backup-GPO (and the Group Policy Management Console) creates one sub
        folder per backup, named after the backup ID. Each folder contains the
        file 'bkupInfo.xml' with the GPO GUID, the GPO display name, the backup
        time and the comment, and the file 'gpreport.xml' with the settings
        report of the GPO at the time of the backup.

        The function reads these files and returns one object per backup, the
        most recent backup first. Folders without a readable 'bkupInfo.xml' are
        ignored.

    .PARAMETER Path
        The backup folder.

    .PARAMETER BackupId
        Returns only the backup with this ID.

    .PARAMETER GpoName
        Returns only backups of GPOs with this display name.

    .PARAMETER GpoId
        Returns only backups of the GPO with this GUID.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]

        Objects with the properties Id, GpoId, GpoName, GpoDomain, BackupTime
        (UTC), Comment, Path, ReportPath, ComputerVersionDirectory,
        ComputerVersionSysvol, UserVersionDirectory and UserVersionSysvol. The
        version properties are $null when 'gpreport.xml' is missing.

    .EXAMPLE
        Get-GPDscBackup -Path '\\fs01\GPOBackup' -GpoName 'Baseline' | Select-Object -First 1

        Returns the most recent backup of the GPO 'Baseline'.
#>
function Get-GPDscBackup
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $BackupId,

        [Parameter()]
        [System.String]
        $GpoName,

        [Parameter()]
        [System.String]
        $GpoId
    )

    if (-not (Test-Path -LiteralPath $Path -PathType 'Container'))
    {
        return @()
    }

    $backups = foreach ($backupFolder in (Get-ChildItem -LiteralPath $Path -Directory -ErrorAction 'SilentlyContinue'))
    {
        $backupInfoPath = Join-Path -Path $backupFolder.FullName -ChildPath 'bkupInfo.xml'

        if (-not (Test-Path -LiteralPath $backupInfoPath -PathType 'Leaf'))
        {
            continue
        }

        try
        {
            $backupInfo = New-Object -TypeName 'System.Xml.XmlDocument'
            $backupInfo.Load($backupInfoPath)

            $backupObject = [PSCustomObject] @{
                Id                       = Get-GPDscXmlGuid -Xml $backupInfo -ElementName 'ID'
                GpoId                    = Get-GPDscXmlGuid -Xml $backupInfo -ElementName 'GPOGuid'
                GpoName                  = Get-GPDscXmlText -Xml $backupInfo -XPath "//*[local-name()='GPODisplayName']"
                GpoDomain                = Get-GPDscXmlText -Xml $backupInfo -XPath "//*[local-name()='GPODomain']"
                BackupTime               = $null
                Comment                  = Get-GPDscXmlText -Xml $backupInfo -XPath "//*[local-name()='Comment']"
                Path                     = $backupFolder.FullName
                ReportPath               = $null
                ComputerVersionDirectory = $null
                ComputerVersionSysvol    = $null
                UserVersionDirectory     = $null
                UserVersionSysvol        = $null
            }

            if ([System.String]::IsNullOrEmpty($backupObject.Id))
            {
                $backupObject.Id = ($backupFolder.Name -replace '[{}]', '').ToLowerInvariant()
            }

            $backupTimeText = Get-GPDscXmlText -Xml $backupInfo -XPath "//*[local-name()='BackupTime']"
            $backupTime = [System.DateTime]::MinValue

            if ([System.DateTime]::TryParse(
                    $backupTimeText,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    ([System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal),
                    [ref] $backupTime))
            {
                $backupObject.BackupTime = $backupTime
            }

            $reportPath = Join-Path -Path $backupFolder.FullName -ChildPath 'gpreport.xml'

            if (Test-Path -LiteralPath $reportPath -PathType 'Leaf')
            {
                $backupObject.ReportPath = $reportPath

                $report = New-Object -TypeName 'System.Xml.XmlDocument'
                $report.Load($reportPath)

                foreach ($section in @('Computer', 'User'))
                {
                    foreach ($versionName in @('VersionDirectory', 'VersionSysvol'))
                    {
                        $versionText = Get-GPDscXmlText -Xml $report -XPath (
                            "/*[local-name()='GPO']/*[local-name()='{0}']/*[local-name()='{1}']" -f $section, $versionName
                        )

                        if (-not [System.String]::IsNullOrEmpty($versionText))
                        {
                            $backupObject.PSObject.Properties[('{0}{1}' -f $section, $versionName)].Value = [System.UInt32] $versionText
                        }
                    }
                }
            }

            $backupObject
        }
        catch
        {
            Write-Verbose -Message ($script:localizedData.BackupFileInvalid -f $backupInfoPath, $_.Exception.Message)
        }
    }

    $backups = @($backups | Where-Object -FilterScript {
            (-not $BackupId -or $_.Id -eq ($BackupId -replace '[{}]', '').ToLowerInvariant()) -and
            (-not $GpoName -or $_.GpoName -eq $GpoName) -and
            (-not $GpoId -or $_.GpoId -eq ($GpoId -replace '[{}]', '').ToLowerInvariant())
        })

    return @($backups | Sort-Object -Property 'BackupTime' -Descending)
}
