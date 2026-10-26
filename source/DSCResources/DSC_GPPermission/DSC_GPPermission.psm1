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
        Returns the current permission of the security principal on the GPO.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER TargetName
        Specifies the name of the security principal.

    .PARAMETER TargetType
        Specifies the type of the security principal.

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
        $TargetName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Computer', 'User', 'Group')]
        [System.String]
        $TargetType,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $TargetName, $Name)

    $getTargetResourceResult = @{
        Name            = $Name
        TargetName      = $TargetName
        TargetType      = $TargetType
        PermissionLevel = $null
        Ensure          = 'Absent'
        Domain          = $Domain
        Server          = $Server
        Inherited       = $null
        TrusteeType     = $null
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

    $permission = Find-GPDscPermission -GpoId $gpo.Id -TargetName $TargetName -Domain $Domain -Server $Server

    if ($null -eq $permission)
    {
        Write-Verbose -Message ($script:localizedData.PermissionNotFound -f $TargetName, $Name)
    }
    else
    {
        $getTargetResourceResult.Ensure = 'Present'
        $getTargetResourceResult.PermissionLevel = [System.String] $permission.Permission
        $getTargetResourceResult.Inherited = [System.Boolean] $permission.Inherited
        $getTargetResourceResult.TrusteeType = [System.String] $permission.TrusteeType

        Write-Verbose -Message ($script:localizedData.PermissionFound -f $TargetName, $Name, $getTargetResourceResult.PermissionLevel, $getTargetResourceResult.Inherited)
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Grants, changes or removes the permission of the security principal on
        the GPO.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER TargetName
        Specifies the name of the security principal.

    .PARAMETER TargetType
        Specifies the type of the security principal.

    .PARAMETER PermissionLevel
        Specifies the permission level of the security principal.

    .PARAMETER Ensure
        Specifies if the permission should be present or absent.

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
        $TargetName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Computer', 'User', 'Group')]
        [System.String]
        $TargetType,

        [Parameter()]
        [ValidateSet('GpoRead', 'GpoApply', 'GpoEdit', 'GpoEditDeleteModifySecurity')]
        [System.String]
        $PermissionLevel,

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

    Assert-PermissionLevelParameter -Ensure $Ensure -PermissionLevel $PermissionLevel

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

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server -DomainParameterName 'DomainName'

    $setPermissionParameters = @{
        Guid        = $gpo.Id
        TargetName  = $TargetName
        TargetType  = $TargetType
        Confirm     = $false
        ErrorAction = 'Stop'
    }

    if ($Ensure -eq 'Present')
    {
        $setPermissionParameters['PermissionLevel'] = $PermissionLevel

        # Without -Replace a higher permission level would never be lowered.
        $setPermissionParameters['Replace'] = $true

        Write-Verbose -Message ($script:localizedData.SettingPermission -f $TargetName, $Name, $PermissionLevel)
    }
    else
    {
        $setPermissionParameters['PermissionLevel'] = 'None'

        Write-Verbose -Message ($script:localizedData.RemovingPermission -f $TargetName, $Name)
    }

    try
    {
        $null = Set-GPPermission @setPermissionParameters @connectionParameters
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.SetPermissionFailed -f $TargetName, $Name) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the permission of the security principal on the GPO is in
        the desired state.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER TargetName
        Specifies the name of the security principal.

    .PARAMETER TargetType
        Specifies the type of the security principal.

    .PARAMETER PermissionLevel
        Specifies the permission level of the security principal.

    .PARAMETER Ensure
        Specifies if the permission should be present or absent.

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
        $TargetName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Computer', 'User', 'Group')]
        [System.String]
        $TargetType,

        [Parameter()]
        [ValidateSet('GpoRead', 'GpoApply', 'GpoEdit', 'GpoEditDeleteModifySecurity')]
        [System.String]
        $PermissionLevel,

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

    Assert-PermissionLevelParameter -Ensure $Ensure -PermissionLevel $PermissionLevel

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $TargetName, $Name)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -TargetName $TargetName -TargetType $TargetType -Domain $Domain -Server $Server

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $TargetName, $Name, $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present' -and $currentState.PermissionLevel -ne $PermissionLevel)
    {
        Write-Verbose -Message ($script:localizedData.PermissionLevelMismatch -f $TargetName, $Name, $PermissionLevel, $currentState.PermissionLevel)

        $inDesiredState = $false
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $TargetName, $Name)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $TargetName, $Name)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Throws when Ensure is Present and no permission level is specified.

    .PARAMETER Ensure
        The value of Ensure.

    .PARAMETER PermissionLevel
        The value of PermissionLevel.
#>
function Assert-PermissionLevelParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.String]
        $PermissionLevel
    )

    if ($Ensure -eq 'Present' -and [System.String]::IsNullOrEmpty($PermissionLevel))
    {
        New-ArgumentException -ArgumentName 'PermissionLevel' -Message $script:localizedData.PermissionLevelRequired
    }
}

<#
    .SYNOPSIS
        Returns the explicit (not denied) permission of a security principal on
        a GPO, or $null.

    .DESCRIPTION
        Uses Get-GPPermission -All, because Get-GPPermission -TargetName throws
        when the principal has no permission. The principal is matched by its
        name ('GPO Admins') or by its domain qualified name
        ('CONTOSO\GPO Admins').

    .PARAMETER GpoId
        The GUID of the GPO.

    .PARAMETER TargetName
        The name of the security principal.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.
#>
function Find-GPDscPermission
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
        $TargetName,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    $connectionParameters = Get-GPDscConnectionParameter -Domain $Domain -Server $Server -DomainParameterName 'DomainName'

    try
    {
        $permissions = Get-GPPermission -Guid $GpoId -All @connectionParameters -ErrorAction 'Stop'
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.GetPermissionFailed -f $GpoId) -ErrorRecord $_
    }

    $matchingPermissions = @($permissions | Where-Object -FilterScript {
            $trustee = $_.Trustee
            $qualifiedName = '{0}\{1}' -f $trustee.Domain, $trustee.Name

            -not $_.Denied -and ($trustee.Name -eq $TargetName -or $qualifiedName -eq $TargetName)
        })

    # Prefer an explicit permission over an inherited one.
    return $matchingPermissions | Sort-Object -Property 'Inherited' | Select-Object -First 1
}

Export-ModuleMember -Function *-TargetResource
