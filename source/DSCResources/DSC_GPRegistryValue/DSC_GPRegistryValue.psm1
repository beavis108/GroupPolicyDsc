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
        Returns the current state of the registry-based policy setting.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Key
        Specifies the registry key.

    .PARAMETER ValueName
        Specifies the name of the registry value.

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
        $Key,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ValueName,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Assert-RegistryKeyHive -Key $Key

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Key, $ValueName, $Name)

    $getTargetResourceResult = @{
        Name        = $Name
        Key         = $Key
        ValueName   = $ValueName
        Type        = $null
        Value       = [System.String[]] @()
        PolicyState = $null
        Ensure      = 'Absent'
        Domain      = $Domain
        Server      = $Server
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

    $registrySetting = Find-GPDscRegistryValue -GpoId $gpo.Id -Key $Key -ValueName $ValueName -Domain $Domain -Server $Server

    if ($null -eq $registrySetting)
    {
        Write-Verbose -Message ($script:localizedData.ValueNotFound -f $Key, $ValueName, $Name)

        return $getTargetResourceResult
    }

    $getTargetResourceResult.Ensure = 'Present'
    $getTargetResourceResult.PolicyState = [System.String] $registrySetting.PolicyState

    if ($getTargetResourceResult.PolicyState -ne 'Delete')
    {
        $getTargetResourceResult.Type = [System.String] $registrySetting.Type
        $getTargetResourceResult.Value = ConvertTo-GPDscComparableRegistryValue -Type $getTargetResourceResult.Type -Value $registrySetting.Value
    }

    if ($getTargetResourceResult.PolicyState -eq 'Delete')
    {
        Write-Verbose -Message ($script:localizedData.ValueFoundDelete -f $Key, $ValueName, $Name)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.ValueFound -f $Key, $ValueName, $Name, $getTargetResourceResult.PolicyState, $getTargetResourceResult.Type, ($getTargetResourceResult.Value -join "', '"))
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Configures or removes the registry-based policy setting.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Key
        Specifies the registry key.

    .PARAMETER ValueName
        Specifies the name of the registry value.

    .PARAMETER Type
        Specifies the registry value type.

    .PARAMETER Value
        Specifies the registry value data.

    .PARAMETER PolicyState
        Specifies if the policy sets ('Set') or deletes ('Delete') the value on
        the clients.

    .PARAMETER Ensure
        Specifies if the setting should be present in the GPO or absent.

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
        $Key,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ValueName,

        [Parameter()]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [System.String]
        $Type,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Value,

        [Parameter()]
        [ValidateSet('Set', 'Delete')]
        [System.String]
        $PolicyState = 'Set',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Assert-RegistryKeyHive -Key $Key
    Assert-TypeParameter -Ensure $Ensure -PolicyState $PolicyState -Type $Type

    if (-not (Assert-GPDscModule))
    {
        return
    }

    $gpo = Get-GPDscGpo -Name $Name -Domain $Domain -Server $Server

    if ($null -eq $gpo)
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        New-InvalidOperationException -Message ($script:localizedData.GpoRequired -f $Name)
    }

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server
    $cmdletValueName = ConvertTo-CmdletValueName -ValueName $ValueName

    if ($Ensure -eq 'Absent')
    {
        if ($null -ne (Find-GPDscRegistryValue -GpoId $gpo.Id -Key $Key -ValueName $ValueName -Domain $Domain -Server $Server))
        {
            Write-Verbose -Message ($script:localizedData.RemovingValue -f $Key, $ValueName, $Name)

            try
            {
                $null = Remove-GPRegistryValue -Guid $gpo.Id -Key $Key -ValueName $cmdletValueName @connectionParameters -Confirm:$false -ErrorAction 'Stop'
            }
            catch
            {
                New-InvalidOperationException -Message ($script:localizedData.ChangeValueFailed -f $Key, $ValueName, $Name) -ErrorRecord $_
            }
        }

        return
    }

    $setValueParameters = @{
        Guid        = $gpo.Id
        Key         = $Key
        ValueName   = $cmdletValueName
        Confirm     = $false
        ErrorAction = 'Stop'
    }

    if ($PolicyState -eq 'Delete')
    {
        $setValueParameters['Disable'] = $true

        Write-Verbose -Message ($script:localizedData.SettingDeleteValue -f $Key, $ValueName, $Name)
    }
    else
    {
        $setValueParameters['Type'] = $Type
        $setValueParameters['Value'] = ConvertTo-GPDscRegistryValue -Type $Type -Value $Value

        Write-Verbose -Message ($script:localizedData.SettingValue -f $Key, $ValueName, $Name, $Type, ($Value -join "', '"))
    }

    try
    {
        $null = Set-GPRegistryValue @setValueParameters @connectionParameters
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeValueFailed -f $Key, $ValueName, $Name) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the registry-based policy setting is in the desired
        state.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Key
        Specifies the registry key.

    .PARAMETER ValueName
        Specifies the name of the registry value.

    .PARAMETER Type
        Specifies the registry value type.

    .PARAMETER Value
        Specifies the registry value data.

    .PARAMETER PolicyState
        Specifies if the policy sets ('Set') or deletes ('Delete') the value on
        the clients.

    .PARAMETER Ensure
        Specifies if the setting should be present in the GPO or absent.

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
        $Key,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ValueName,

        [Parameter()]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [System.String]
        $Type,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Value,

        [Parameter()]
        [ValidateSet('Set', 'Delete')]
        [System.String]
        $PolicyState = 'Set',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Assert-TypeParameter -Ensure $Ensure -PolicyState $PolicyState -Type $Type

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Key, $ValueName, $Name)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -Key $Key -ValueName $ValueName -Domain $Domain -Server $Server

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $Key, $ValueName, $Name, $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present')
    {
        if ($currentState.PolicyState -ne $PolicyState)
        {
            Write-Verbose -Message ($script:localizedData.PropertyMismatch -f $Key, $ValueName, 'PolicyState', $PolicyState, $currentState.PolicyState)

            $inDesiredState = $false
        }
        elseif ($PolicyState -eq 'Set')
        {
            $desiredValue = ConvertTo-GPDscComparableRegistryValue -Type $Type -Value (ConvertTo-GPDscRegistryValue -Type $Type -Value $Value)

            if ($currentState.Type -ne $Type)
            {
                Write-Verbose -Message ($script:localizedData.PropertyMismatch -f $Key, $ValueName, 'Type', $Type, $currentState.Type)

                $inDesiredState = $false
            }
            elseif (($currentState.Value -join "`n") -cne ($desiredValue -join "`n") -or @($currentState.Value).Count -ne @($desiredValue).Count)
            {
                Write-Verbose -Message ($script:localizedData.PropertyMismatch -f $Key, $ValueName, 'Value', ($desiredValue -join "', '"), ($currentState.Value -join "', '"))

                $inDesiredState = $false
            }
        }
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Key, $ValueName, $Name)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Key, $ValueName, $Name)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Throws when the registry key is not in HKEY_LOCAL_MACHINE or
        HKEY_CURRENT_USER.

    .PARAMETER Key
        The registry key.
#>
function Assert-RegistryKeyHive
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key
    )

    if ($Key -notmatch '^(HKLM|HKCU|HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\.+')
    {
        New-ArgumentException -ArgumentName 'Key' -Message ($script:localizedData.InvalidKey -f $Key)
    }
}

<#
    .SYNOPSIS
        Throws when Type is missing for a value that is set.

    .PARAMETER Ensure
        The value of Ensure.

    .PARAMETER PolicyState
        The value of PolicyState.

    .PARAMETER Type
        The value of Type.
#>
function Assert-TypeParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PolicyState,

        [Parameter()]
        [System.String]
        $Type
    )

    if ($Ensure -eq 'Present' -and $PolicyState -eq 'Set' -and [System.String]::IsNullOrEmpty($Type))
    {
        New-ArgumentException -ArgumentName 'Type' -Message $script:localizedData.TypeRequired
    }
}

<#
    .SYNOPSIS
        Converts the value name of the configuration to the value name used by
        the GroupPolicy cmdlets. '(Default)' is the default value of the key.

    .PARAMETER ValueName
        The value name.
#>
function ConvertTo-CmdletValueName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ValueName
    )

    if ($ValueName -eq '(Default)')
    {
        return [System.String]::Empty
    }


    return $ValueName
}

<#
    .SYNOPSIS
        Returns the registry-based policy setting of a value, or $null.

    .DESCRIPTION
        Get-GPRegistryValue writes an error when the key or value is not
        configured in the GPO. The existence of the GPO has been verified
        before, so every error is treated as 'not configured'.

    .PARAMETER GpoId
        The GUID of the GPO.

    .PARAMETER Key
        The registry key.

    .PARAMETER ValueName
        The name of the registry value.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.
#>
function Find-GPDscRegistryValue
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Guid]
        $GpoId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ValueName,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server
    $cmdletValueName = ConvertTo-CmdletValueName -ValueName $ValueName

    try
    {
        $registrySettings = Get-GPRegistryValue -Guid $GpoId -Key $Key -ValueName $cmdletValueName @connectionParameters -ErrorAction 'Stop'
    }
    catch
    {
        # Get-GPRegistryValue throws an ArgumentException when the value is not configured.
        if ($_.Exception -isnot [System.ArgumentException])
        {
            Write-Verbose -Message ($script:localizedData.ValueQueryError -f $Key, $ValueName, $_.Exception.Message)
        }

        return $null
    }

    return $registrySettings | Where-Object -FilterScript {
        $_.PSObject.Properties['ValueName'] -and
        (ConvertTo-CmdletValueName -ValueName ([System.String] $_.ValueName)) -eq $cmdletValueName -and
        $null -ne $_.PolicyState
    } | Select-Object -First 1
}

Export-ModuleMember -Function *-TargetResource
