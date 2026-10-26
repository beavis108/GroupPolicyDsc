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
        Returns the current state of the Registry preference item.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Context
        Specifies the configuration of the GPO (Computer or User).

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
        [ValidateSet('Computer', 'User')]
        [System.String]
        $Context,

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

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Key, $ValueName, $Context, $Name)

    $getTargetResourceResult = @{
        Name      = $Name
        Context   = $Context
        Key       = $Key
        ValueName = $ValueName
        Action    = $null
        Type      = $null
        Value     = [System.String[]] @()
        Disabled  = $null
        Ensure    = 'Absent'
        Domain    = $Domain
        Server    = $Server
        Order     = $null
        ItemCount = [System.UInt32] 0
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

    $preferenceItems = @(Find-GPDscPrefRegistryValue -GpoId $gpo.Id -Context $Context -Key $Key -ValueName $ValueName -Domain $Domain -Server $Server)

    $getTargetResourceResult.ItemCount = [System.UInt32] $preferenceItems.Count

    if ($preferenceItems.Count -eq 0)
    {
        Write-Verbose -Message ($script:localizedData.ItemNotFound -f $Key, $ValueName, $Context, $Name)

        return $getTargetResourceResult
    }

    # When several items exist, the one with the highest order wins on the clients.
    $preferenceItem = $preferenceItems | Sort-Object -Property { [System.Int32] $_.Order } -Descending | Select-Object -First 1

    $getTargetResourceResult.Ensure = 'Present'
    $getTargetResourceResult.Action = [System.String] $preferenceItem.Action
    $getTargetResourceResult.Disabled = [System.Boolean] $preferenceItem.DisabledDirectly
    $getTargetResourceResult.Order = [System.Int32] $preferenceItem.Order

    if ($preferenceItem.HasValue -and -not [System.String]::IsNullOrEmpty([System.String] $preferenceItem.Type))
    {
        $getTargetResourceResult.Type = [System.String] $preferenceItem.Type

        if ($getTargetResourceResult.Type -in @('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord'))
        {
            $getTargetResourceResult.Value = ConvertTo-GPDscComparableRegistryValue -Type $getTargetResourceResult.Type -Value $preferenceItem.Value
        }
    }

    Write-Verbose -Message ($script:localizedData.ItemFound -f $Key, $ValueName, $Context, $Name, $getTargetResourceResult.Action, $preferenceItems.Count)

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Configures or removes the Registry preference item.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Context
        Specifies the configuration of the GPO (Computer or User).

    .PARAMETER Key
        Specifies the registry key.

    .PARAMETER ValueName
        Specifies the name of the registry value.

    .PARAMETER Action
        Specifies the action of the preference item.

    .PARAMETER Type
        Specifies the registry value type.

    .PARAMETER Value
        Specifies the registry value data.

    .PARAMETER Disabled
        Specifies if the preference item is disabled.

    .PARAMETER Ensure
        Specifies if the preference item should be present or absent.

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
        [ValidateSet('Computer', 'User')]
        [System.String]
        $Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Key,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ValueName,

        [Parameter()]
        [ValidateSet('Create', 'Replace', 'Update', 'Delete')]
        [System.String]
        $Action = 'Update',

        [Parameter()]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [System.String]
        $Type,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Value,

        [Parameter()]
        [System.Boolean]
        $Disabled = $false,

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

    Assert-PreferenceTypeParameter -Ensure $Ensure -Action $Action -Type $Type

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

    $existingItems = @(Find-GPDscPrefRegistryValue -GpoId $gpo.Id -Context $Context -Key $Key -ValueName $ValueName -Domain $Domain -Server $Server)

    try
    {
        <#
            Set-GPPrefRegistryValue always creates a new preference item, it
            never changes an existing one. Existing items are therefore removed
            before the item is created again.
        #>
        if ($existingItems.Count -gt 0)
        {
            Write-Verbose -Message ($script:localizedData.RemovingItem -f $Key, $ValueName, $Context, $Name, $existingItems.Count)

            $null = Remove-GPPrefRegistryValue -Guid $gpo.Id -Context $Context -Key $Key -ValueName $ValueName @connectionParameters -Confirm:$false -ErrorAction 'Stop'
        }

        if ($Ensure -eq 'Absent')
        {
            return
        }

        $setItemParameters = @{
            Guid        = $gpo.Id
            Context     = $Context
            Key         = $Key
            ValueName   = $ValueName
            Action      = $Action
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if (-not [System.String]::IsNullOrEmpty($Type))
        {
            $setItemParameters['Type'] = $Type
            $setItemParameters['Value'] = ConvertTo-GPDscRegistryValue -Type $Type -Value $Value
        }

        if ($Disabled)
        {
            $setItemParameters['Disable'] = $true
        }

        Write-Verbose -Message ($script:localizedData.CreatingItem -f $Key, $ValueName, $Context, $Name, $Action)

        $null = Set-GPPrefRegistryValue @setItemParameters @connectionParameters
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeItemFailed -f $Key, $ValueName, $Context, $Name) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the Registry preference item is in the desired state.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Context
        Specifies the configuration of the GPO (Computer or User).

    .PARAMETER Key
        Specifies the registry key.

    .PARAMETER ValueName
        Specifies the name of the registry value.

    .PARAMETER Action
        Specifies the action of the preference item.

    .PARAMETER Type
        Specifies the registry value type.

    .PARAMETER Value
        Specifies the registry value data.

    .PARAMETER Disabled
        Specifies if the preference item is disabled.

    .PARAMETER Ensure
        Specifies if the preference item should be present or absent.

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
        [ValidateSet('Computer', 'User')]
        [System.String]
        $Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Key,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ValueName,

        [Parameter()]
        [ValidateSet('Create', 'Replace', 'Update', 'Delete')]
        [System.String]
        $Action = 'Update',

        [Parameter()]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [System.String]
        $Type,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Value,

        [Parameter()]
        [System.Boolean]
        $Disabled = $false,

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

    Assert-PreferenceTypeParameter -Ensure $Ensure -Action $Action -Type $Type

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Key, $ValueName, $Context, $Name)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -Context $Context -Key $Key -ValueName $ValueName -Domain $Domain -Server $Server

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $Key, $ValueName, $Context, $Name, $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present')
    {
        if ($currentState.ItemCount -gt 1)
        {
            Write-Verbose -Message ($script:localizedData.DuplicateItems -f $Key, $ValueName, $Context, $Name, $currentState.ItemCount)

            $inDesiredState = $false
        }

        $desiredValues = @{
            Action   = $Action
            Disabled = [System.String] $Disabled
        }

        if (-not [System.String]::IsNullOrEmpty($Type))
        {
            $desiredValues['Type'] = $Type
            $desiredValues['Value'] = (ConvertTo-GPDscComparableRegistryValue -Type $Type -Value (ConvertTo-GPDscRegistryValue -Type $Type -Value $Value)) -join "`n"
        }

        $currentValues = @{
            Action   = [System.String] $currentState.Action
            Disabled = [System.String] $currentState.Disabled
            Type     = [System.String] $currentState.Type
            Value    = $currentState.Value -join "`n"
        }

        foreach ($propertyName in $desiredValues.Keys)
        {
            if ($currentValues[$propertyName] -cne $desiredValues[$propertyName])
            {
                Write-Verbose -Message ($script:localizedData.PropertyMismatch -f $Key, $ValueName, $propertyName, $desiredValues[$propertyName], $currentValues[$propertyName])

                $inDesiredState = $false
            }
        }
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Key, $ValueName, $Context, $Name)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Key, $ValueName, $Context, $Name)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Throws when Type is missing for an action that writes a value.

    .PARAMETER Ensure
        The value of Ensure.

    .PARAMETER Action
        The value of Action.

    .PARAMETER Type
        The value of Type.
#>
function Assert-PreferenceTypeParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Action,

        [Parameter()]
        [System.String]
        $Type
    )

    if ($Ensure -eq 'Present' -and $Action -ne 'Delete' -and [System.String]::IsNullOrEmpty($Type))
    {
        New-ArgumentException -ArgumentName 'Type' -Message $script:localizedData.TypeRequired
    }
}

<#
    .SYNOPSIS
        Returns all Registry preference items of a registry value.

    .DESCRIPTION
        Get-GPPrefRegistryValue writes an error when no item exists. The
        existence of the GPO has been verified before, so every error is
        treated as 'no item'.

    .PARAMETER GpoId
        The GUID of the GPO.

    .PARAMETER Context
        The configuration of the GPO (Computer or User).

    .PARAMETER Key
        The registry key.

    .PARAMETER ValueName
        The name of the registry value.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.
#>
function Find-GPDscPrefRegistryValue
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Guid]
        $GpoId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Context,

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

    try
    {
        $preferenceItems = Get-GPPrefRegistryValue -Guid $GpoId -Context $Context -Key $Key -ValueName $ValueName @connectionParameters -ErrorAction 'Stop'
    }
    catch
    {
        # Get-GPPrefRegistryValue throws an ArgumentException when no item exists.
        if ($_.Exception -isnot [System.ArgumentException])
        {
            Write-Verbose -Message ($script:localizedData.ItemQueryError -f $Key, $ValueName, $_.Exception.Message)
        }

        return @()
    }

    return @($preferenceItems | Where-Object -FilterScript {
            [System.String] $_.ValueName -eq $ValueName
        })
}

Export-ModuleMember -Function *-TargetResource
