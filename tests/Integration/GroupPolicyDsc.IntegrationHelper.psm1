<#
    .SYNOPSIS
        Helper functions for the integration tests of GroupPolicyDsc.

    .DESCRIPTION
        The integration tests create, change and remove real GPOs, links and an
        organizational unit in the domain of the test machine. They only run
        on a domain controller of a lab domain and only when the environment
        variable GPDSC_INTEGRATION_TEST is set to '1'. All objects created by
        the tests start with 'GPDscIT'.
#>

$script:testPrefix = 'GPDscIT'

<#
    .SYNOPSIS
        Returns $true when the integration tests may run on this machine.
#>
function Test-GPDscIntegrationEnvironment
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    if ($env:GPDSC_INTEGRATION_TEST -ne '1')
    {
        Write-Warning -Message 'GroupPolicyDsc integration tests are skipped. Set $env:GPDSC_INTEGRATION_TEST = ''1'' on a domain controller of a LAB domain to run them.'

        return $false
    }

    if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core')
    {
        return $false
    }

    # 4 = backup domain controller, 5 = primary domain controller
    $domainRole = (Get-CimInstance -ClassName 'Win32_ComputerSystem').DomainRole

    if ($domainRole -lt 4)
    {
        Write-Warning -Message 'GroupPolicyDsc integration tests are skipped. They must run on a domain controller.'

        return $false
    }

    return [System.Boolean] (Get-Module -Name 'GroupPolicy' -ListAvailable)
}

<#
    .SYNOPSIS
        Returns the names and paths used by the integration tests.
#>
function Get-GPDscIntegrationSetting
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    $rootDse = [System.DirectoryServices.DirectoryEntry] 'LDAP://RootDSE'
    $domainDn = [System.String] $rootDse.Properties['defaultNamingContext'].Value
    $configurationDn = [System.String] $rootDse.Properties['configurationNamingContext'].Value
    $domainName = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
    $siteName = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name

    return @{
        Prefix     = $script:testPrefix
        DomainName = $domainName
        DomainDN   = $domainDn
        OuDN       = 'OU={0},{1}' -f $script:testPrefix, $domainDn
        SiteDN     = 'CN={0},CN=Sites,{1}' -f $siteName, $configurationDn
        WorkPath   = Join-Path -Path $env:SystemDrive -ChildPath $script:testPrefix
    }
}

<#
    .SYNOPSIS
        Creates the organizational unit used by the integration tests.
#>
function New-GPDscTestOrganizationalUnit
{
    [CmdletBinding()]
    param ()

    $setting = Get-GPDscIntegrationSetting

    if (-not [System.DirectoryServices.DirectoryEntry]::Exists("LDAP://$($setting.OuDN)"))
    {
        $domain = [System.DirectoryServices.DirectoryEntry] "LDAP://$($setting.DomainDN)"
        $organizationalUnit = $domain.Children.Add("OU=$($setting.Prefix)", 'organizationalUnit')
        $organizationalUnit.CommitChanges()
    }
}

<#
    .SYNOPSIS
        Removes the organizational unit used by the integration tests.
#>
function Remove-GPDscTestOrganizationalUnit
{
    [CmdletBinding()]
    param ()

    $setting = Get-GPDscIntegrationSetting

    if ([System.DirectoryServices.DirectoryEntry]::Exists("LDAP://$($setting.OuDN)"))
    {
        ([System.DirectoryServices.DirectoryEntry] "LDAP://$($setting.OuDN)").DeleteTree()
    }
}

<#
    .SYNOPSIS
        Creates a GPO for the integration tests (removes an existing one first).
#>
function New-GPDscTestGpo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Remove-GPDscTestGpo -Name $Name

    return New-GPO -Name $Name -Comment 'GroupPolicyDsc integration test' -ErrorAction 'Stop'
}

<#
    .SYNOPSIS
        Removes GPOs created by the integration tests.
#>
function Remove-GPDscTestGpo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Name
    )

    foreach ($gpoName in $Name)
    {
        if (-not $gpoName.StartsWith($script:testPrefix))
        {
            throw "Refusing to remove the GPO '$gpoName', it was not created by the integration tests."
        }

        $gpo = Get-GPO -All | Where-Object -FilterScript { $_.DisplayName -eq $gpoName }

        foreach ($gpoToRemove in $gpo)
        {
            Remove-GPO -Guid $gpoToRemove.Id -Confirm:$false
        }
    }
}

<#
    .SYNOPSIS
        Removes a Starter GPO created by the integration tests.

    .DESCRIPTION
        The module GroupPolicy has no cmdlet to remove a Starter GPO. Starter
        GPOs are only stored in SYSVOL, so the folder is removed.
#>
function Remove-GPDscTestStarterGpo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    if (-not $Name.StartsWith($script:testPrefix))
    {
        throw "Refusing to remove the Starter GPO '$Name', it was not created by the integration tests."
    }

    $setting = Get-GPDscIntegrationSetting
    $starterGpo = Get-GPStarterGPO -All | Where-Object -FilterScript { $_.DisplayName -eq $Name }

    foreach ($starterGpoToRemove in $starterGpo)
    {
        $path = '\\{0}\SYSVOL\{0}\StarterGPOs\{{{1}}}' -f $setting.DomainName, $starterGpoToRemove.Id

        if (Test-Path -LiteralPath $path)
        {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

<#
    .SYNOPSIS
        Returns $true when the Starter GPOs folder exists in SYSVOL.
#>
function Test-GPDscStarterGpoFolder
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    $setting = Get-GPDscIntegrationSetting

    return Test-Path -LiteralPath ('\\{0}\SYSVOL\{0}\StarterGPOs' -f $setting.DomainName)
}

<#
    .SYNOPSIS
        Removes and recreates a work folder below C:\GPDscIT.
#>
function Reset-GPDscTestFolder
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ChildPath
    )

    $setting = Get-GPDscIntegrationSetting
    $path = Join-Path -Path $setting.WorkPath -ChildPath $ChildPath

    if (Test-Path -LiteralPath $path)
    {
        Remove-Item -LiteralPath $path -Recurse -Force
    }

    $null = New-Item -Path $path -ItemType 'Directory' -Force

    return $path
}

<#
    .SYNOPSIS
        Removes a work folder below C:\GPDscIT, and C:\GPDscIT when it is empty.
#>
function Remove-GPDscTestFolder
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ChildPath
    )

    $setting = Get-GPDscIntegrationSetting
    $path = Join-Path -Path $setting.WorkPath -ChildPath $ChildPath

    if (Test-Path -LiteralPath $path)
    {
        Remove-Item -LiteralPath $path -Recurse -Force
    }

    if ((Test-Path -LiteralPath $setting.WorkPath) -and -not (Get-ChildItem -LiteralPath $setting.WorkPath -Force))
    {
        Remove-Item -LiteralPath $setting.WorkPath -Force
    }
}

Export-ModuleMember -Function *
