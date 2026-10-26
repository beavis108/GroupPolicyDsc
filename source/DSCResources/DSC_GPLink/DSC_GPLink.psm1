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
        Returns the current state of the GPO link.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Target
        Specifies the distinguished name of the site, domain or organizational
        unit the GPO is linked to.

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
        $Target,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $Name, $Target)

    $getTargetResourceResult = @{
        Name        = $Name
        Target      = $Target
        Domain      = $Domain
        Server      = $Server
        LinkEnabled = $null
        Enforced    = $null
        Order       = $null
        Ensure      = 'Absent'
        GpoId       = $null
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

    $gpoLink = Find-GPDscLink -GpoId $gpo.Id -Target $Target -Domain $Domain -Server $Server

    if ($null -eq $gpoLink)
    {
        Write-Verbose -Message ($script:localizedData.LinkNotFound -f $Name, $Target)
    }
    else
    {
        $getTargetResourceResult.Ensure = 'Present'
        $getTargetResourceResult.LinkEnabled = [System.Boolean] $gpoLink.Enabled
        $getTargetResourceResult.Enforced = [System.Boolean] $gpoLink.Enforced
        $getTargetResourceResult.Order = [System.UInt32] $gpoLink.Order

        Write-Verbose -Message ($script:localizedData.LinkFound -f $Name, $Target, $gpoLink.Enabled, $gpoLink.Enforced, $gpoLink.Order)
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Creates, changes or removes the GPO link.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Target
        Specifies the distinguished name of the site, domain or organizational
        unit the GPO is linked to.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain of the GPO.

    .PARAMETER Server
        Specifies the domain controller to contact.

    .PARAMETER LinkEnabled
        Specifies if the link is enabled.

    .PARAMETER Enforced
        Specifies if the link is enforced.

    .PARAMETER Order
        Specifies the link order.

    .PARAMETER Ensure
        Specifies if the link should be present or absent.
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
        $Target,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Boolean]
        $LinkEnabled,

        [Parameter()]
        [System.Boolean]
        $Enforced,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [System.UInt32]
        $Order,

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

    if ($null -eq $gpo)
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        New-InvalidOperationException -Message ($script:localizedData.GpoRequired -f $Name)
    }

    $gpoLink = Find-GPDscLink -GpoId $gpo.Id -Target $Target -Domain $Domain -Server $Server

    try
    {
        if ($Ensure -eq 'Absent')
        {
            if ($null -ne $gpoLink)
            {
                Write-Verbose -Message ($script:localizedData.RemovingLink -f $Name, $Target)

                $null = Remove-GPLink -Guid $gpo.Id -Target $Target @connectionParameters -Confirm:$false -ErrorAction 'Stop'
            }

            return
        }

        $linkParameters = @{}

        if ($PSBoundParameters.ContainsKey('LinkEnabled') -and ($null -eq $gpoLink -or [System.Boolean] $gpoLink.Enabled -ne $LinkEnabled))
        {
            $linkParameters['LinkEnabled'] = ConvertTo-GPDscYesNo -Value $LinkEnabled
        }

        if ($PSBoundParameters.ContainsKey('Enforced') -and ($null -eq $gpoLink -or [System.Boolean] $gpoLink.Enforced -ne $Enforced))
        {
            $linkParameters['Enforced'] = ConvertTo-GPDscYesNo -Value $Enforced
        }

        if ($PSBoundParameters.ContainsKey('Order') -and ($null -eq $gpoLink -or [System.UInt32] $gpoLink.Order -ne $Order))
        {
            $linkParameters['Order'] = [System.Int32] $Order
        }

        if ($null -eq $gpoLink)
        {
            Write-Verbose -Message ($script:localizedData.CreatingLink -f $Name, $Target)

            $null = New-GPLink -Guid $gpo.Id -Target $Target @linkParameters @connectionParameters -Confirm:$false -ErrorAction 'Stop'
        }
        elseif ($linkParameters.Count -gt 0)
        {
            Write-Verbose -Message ($script:localizedData.UpdatingLink -f $Name, $Target, ($linkParameters.Keys -join "', '"))

            $null = Set-GPLink -Guid $gpo.Id -Target $Target @linkParameters @connectionParameters -Confirm:$false -ErrorAction 'Stop'
        }
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeLinkFailed -f $Name, $Target) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the GPO link is in the desired state.

    .PARAMETER Name
        Specifies the display name of the GPO.

    .PARAMETER Target
        Specifies the distinguished name of the site, domain or organizational
        unit the GPO is linked to.

    .PARAMETER Domain
        Specifies the fully qualified domain name of the domain of the GPO.

    .PARAMETER Server
        Specifies the domain controller to contact.

    .PARAMETER LinkEnabled
        Specifies if the link is enabled.

    .PARAMETER Enforced
        Specifies if the link is enforced.

    .PARAMETER Order
        Specifies the link order.

    .PARAMETER Ensure
        Specifies if the link should be present or absent.
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
        $Target,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Boolean]
        $LinkEnabled,

        [Parameter()]
        [System.Boolean]
        $Enforced,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [System.UInt32]
        $Order,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $Name, $Target)

    if (-not (Test-GPDscModuleAvailable))
    {
        Write-Verbose -Message $script:localizedData.ModuleNotAvailable

        return $false
    }

    $currentState = Get-TargetResource -Name $Name -Target $Target -Domain $Domain -Server $Server

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $Name, $Target, $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present')
    {
        foreach ($propertyName in @('LinkEnabled', 'Enforced', 'Order'))
        {
            if ($PSBoundParameters.ContainsKey($propertyName) -and [System.String] $currentState[$propertyName] -ne [System.String] $PSBoundParameters[$propertyName])
            {
                Write-Verbose -Message ($script:localizedData.PropertyMismatch -f $Name, $Target, $propertyName, $PSBoundParameters[$propertyName], $currentState[$propertyName])

                $inDesiredState = $false
            }
        }
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Name, $Target)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Name, $Target)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Returns the link of a GPO to a container, or $null.

    .PARAMETER GpoId
        The GUID of the GPO.

    .PARAMETER Target
        The distinguished name of the container.

    .PARAMETER Domain
        The fully qualified domain name.

    .PARAMETER Server
        The domain controller to contact.
#>
function Find-GPDscLink
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
        $Target,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    return Get-GPDscGpoLink -Target $Target -Domain $Domain -Server $Server | Where-Object -FilterScript {
        [System.Guid] $_.GpoId -eq $GpoId
    } | Select-Object -First 1
}

Export-ModuleMember -Function *-TargetResource
