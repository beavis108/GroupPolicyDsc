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
        Returns the current state of the Group Policy Object.

    .PARAMETER Name
        Specifies the display name of the GPO.

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

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Name)

    $getTargetResourceResult = @{
        Name            = $Name
        Domain          = $Domain
        Server          = $Server
        Comment         = $null
        Status          = $null
        WmiFilterName   = $null
        StarterGpoName  = $null
        PreviousName    = $null
        KeepLinks       = $null
        Ensure          = 'Absent'
        Id              = $null
        Owner           = $null
        ComputerVersion = $null
        UserVersion     = $null
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

    $getTargetResourceResult.Ensure = 'Present'
    $getTargetResourceResult.Comment = [System.String] $gpo.Description
    $getTargetResourceResult.Status = [System.String] $gpo.GpoStatus
    $getTargetResourceResult.WmiFilterName = Get-WmiFilterName -Gpo $gpo
    $getTargetResourceResult.Id = [System.String] $gpo.Id
    $getTargetResourceResult.Owner = [System.String] $gpo.Owner

    if ($null -ne $gpo.Computer)
    {
        $getTargetResourceResult.ComputerVersion = [System.UInt32] $gpo.Computer.DSVersion
    }

    if ($null -ne $gpo.User)
    {
        $getTargetResourceResult.UserVersion = [System.UInt32] $gpo.User.DSVersion
    }

    Write-Verbose -Message ($script:localizedData.GpoFound -f $Name, $getTargetResourceResult.Id, $getTargetResourceResult.Status)

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Creates, renames, changes or removes the Group Policy Object.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain of the GPO.

    .PARAMETER Server
        Specifies the domain controller to contact.

    .PARAMETER Comment
        Specifies the comment (description) of the GPO.

    .PARAMETER Status
        Specifies which parts of the GPO are enabled.

    .PARAMETER WmiFilterName
        Specifies the name of the WMI filter linked to the GPO. An empty string
        removes the WMI filter.

    .PARAMETER StarterGpoName
        Specifies the Starter GPO the GPO is created from.

    .PARAMETER PreviousName
        Specifies a previous display name of the GPO. A GPO with this name is
        renamed instead of creating a new GPO.

    .PARAMETER KeepLinks
        Specifies if the links of the GPO are kept when the GPO is removed.

    .PARAMETER Ensure
        Specifies if the GPO should be present or absent.
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
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [ValidateSet('AllSettingsEnabled', 'UserSettingsDisabled', 'ComputerSettingsDisabled', 'AllSettingsDisabled')]
        [System.String]
        $Status,

        [Parameter()]
        [System.String]
        $WmiFilterName,

        [Parameter()]
        [System.String]
        $StarterGpoName,

        [Parameter()]
        [System.String]
        $PreviousName,

        [Parameter()]
        [System.Boolean]
        $KeepLinks = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    if (-not (Assert-GPDscModule))
    {
        return
    }

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server

    $gpo = Get-GPDscGpo -Name $Name -Domain $Domain -Server $Server

    if ($Ensure -eq 'Absent')
    {
        if ($null -ne $gpo)
        {
            Write-Verbose -Message ($script:localizedData.RemovingGpo -f $Name, $KeepLinks)

            try
            {
                Remove-GPO -Guid $gpo.Id -KeepLinks:$KeepLinks @connectionParameters -Confirm:$false -ErrorAction 'Stop'
            }
            catch
            {
                New-InvalidOperationException -Message ($script:localizedData.RemoveGpoFailed -f $Name) -ErrorRecord $_
            }
        }

        return
    }

    if ($null -eq $gpo -and -not [System.String]::IsNullOrWhiteSpace($PreviousName))
    {
        $previousGpo = Get-GPDscGpo -Name $PreviousName -Domain $Domain -Server $Server

        if ($null -ne $previousGpo)
        {
            Write-Verbose -Message ($script:localizedData.RenamingGpo -f $PreviousName, $Name)

            try
            {
                $gpo = Rename-GPO -Guid $previousGpo.Id -TargetName $Name @connectionParameters -Confirm:$false -ErrorAction 'Stop'
            }
            catch
            {
                New-InvalidOperationException -Message ($script:localizedData.RenameGpoFailed -f $PreviousName, $Name) -ErrorRecord $_
            }

            if ($null -eq $gpo)
            {
                $gpo = Get-GPDscGpo -Name $Name -Domain $Domain -Server $Server
            }

            # Never create a second GPO when the renamed GPO can not be read back.
            if ($null -eq $gpo)
            {
                New-InvalidOperationException -Message ($script:localizedData.RenameGpoFailed -f $PreviousName, $Name)
            }
        }
    }

    if ($null -eq $gpo)
    {
        $newGpoParameters = @{
            Name        = $Name
            ErrorAction = 'Stop'
        }

        if (-not [System.String]::IsNullOrEmpty($Comment))
        {
            $newGpoParameters['Comment'] = $Comment
        }

        if (-not [System.String]::IsNullOrWhiteSpace($StarterGpoName))
        {
            if ($null -eq (Get-GPDscStarterGpo -Name $StarterGpoName -Domain $Domain -Server $Server))
            {
                New-InvalidOperationException -Message ($script:localizedData.StarterGpoNotFound -f $StarterGpoName)
            }

            $newGpoParameters['StarterGpoName'] = $StarterGpoName
        }

        Write-Verbose -Message ($script:localizedData.CreatingGpo -f $Name)

        try
        {
            $gpo = New-GPO @newGpoParameters @connectionParameters -Confirm:$false
        }
        catch
        {
            New-InvalidOperationException -Message ($script:localizedData.CreateGpoFailed -f $Name) -ErrorRecord $_
        }
    }

    $wmiFilter = $null
    $changeWmiFilter = $false

    if ($PSBoundParameters.ContainsKey('WmiFilterName'))
    {
        if ((Get-WmiFilterName -Gpo $gpo) -ne [System.String] $WmiFilterName)
        {
            $changeWmiFilter = $true

            if (-not [System.String]::IsNullOrEmpty($WmiFilterName))
            {
                $wmiFilter = Get-GPDscWmiFilter -Name $WmiFilterName -Domain $Domain -Server $Server

                if ($null -eq $wmiFilter)
                {
                    New-InvalidOperationException -Message ($script:localizedData.WmiFilterNotFound -f $WmiFilterName)
                }
            }
        }
    }

    try
    {
        if ($PSBoundParameters.ContainsKey('Comment') -and [System.String] $gpo.Description -cne [System.String] $Comment)
        {
            Write-Verbose -Message ($script:localizedData.SettingComment -f $Name, $Comment)

            $gpo.Description = $Comment
        }

        if ($PSBoundParameters.ContainsKey('Status') -and [System.String] $gpo.GpoStatus -ne $Status)
        {
            Write-Verbose -Message ($script:localizedData.SettingStatus -f $Name, $Status)

            $gpo.GpoStatus = $Status
        }

        if ($changeWmiFilter)
        {
            if ($null -eq $wmiFilter)
            {
                Write-Verbose -Message ($script:localizedData.RemovingWmiFilter -f $Name)
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.SettingWmiFilter -f $Name, $WmiFilterName)
            }

            $gpo.WmiFilter = $wmiFilter
        }
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeGpoFailed -f $Name) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the Group Policy Object is in the desired state.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain of the GPO.

    .PARAMETER Server
        Specifies the domain controller to contact.

    .PARAMETER Comment
        Specifies the comment (description) of the GPO.

    .PARAMETER Status
        Specifies which parts of the GPO are enabled.

    .PARAMETER WmiFilterName
        Specifies the name of the WMI filter linked to the GPO. An empty string
        removes the WMI filter.

    .PARAMETER StarterGpoName
        Specifies the Starter GPO the GPO is created from.

    .PARAMETER PreviousName
        Specifies a previous display name of the GPO.

    .PARAMETER KeepLinks
        Specifies if the links of the GPO are kept when the GPO is removed.

    .PARAMETER Ensure
        Specifies if the GPO should be present or absent.
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
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [ValidateSet('AllSettingsEnabled', 'UserSettingsDisabled', 'ComputerSettingsDisabled', 'AllSettingsDisabled')]
        [System.String]
        $Status,

        [Parameter()]
        [System.String]
        $WmiFilterName,

        [Parameter()]
        [System.String]
        $StarterGpoName,

        [Parameter()]
        [System.String]
        $PreviousName,

        [Parameter()]
        [System.Boolean]
        $KeepLinks = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Name)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -Domain $Domain -Server $Server

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $Name, $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present')
    {
        $desiredValues = @{}

        foreach ($propertyName in @('Comment', 'Status', 'WmiFilterName'))
        {
            if ($PSBoundParameters.ContainsKey($propertyName))
            {
                $desiredValues[$propertyName] = [System.String] $PSBoundParameters[$propertyName]
            }
        }

        foreach ($propertyName in $desiredValues.Keys)
        {
            if ([System.String] $currentState[$propertyName] -cne $desiredValues[$propertyName])
            {
                Write-Verbose -Message ($script:localizedData.PropertyMismatch -f $Name, $propertyName, $desiredValues[$propertyName], $currentState[$propertyName])

                $inDesiredState = $false
            }
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
        Returns the name of the WMI filter linked to a GPO, or an empty string.

    .PARAMETER Gpo
        The GPO object.
#>
function Get-WmiFilterName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Gpo
    )

    if ($null -eq $Gpo.WmiFilter)
    {
        return [System.String]::Empty
    }

    return [System.String] $Gpo.WmiFilter.Name
}

Export-ModuleMember -Function *-TargetResource
