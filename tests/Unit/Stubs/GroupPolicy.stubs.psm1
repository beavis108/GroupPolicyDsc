# Name: GroupPolicy
# Generated from the official cmdlet documentation (windows-powershell-docs, winserver2025-ps).
# Hand-maintained stubs, see README.md.

function Backup-GPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
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
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $All
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Copy-GPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $SourceGuid,

        [Parameter()]
        [System.String]
        $SourceName,

        [Parameter()]
        [System.String]
        $TargetName,

        [Parameter()]
        [System.String]
        $SourceDomain,

        [Parameter()]
        [System.String]
        $TargetDomain,

        [Parameter()]
        [System.String]
        $SourceDomainController,

        [Parameter()]
        [System.String]
        $TargetDomainController,

        [Parameter()]
        [System.String]
        $MigrationTable,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $CopyAcl
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPInheritance
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Target,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPO
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $All
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPOReport
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $ReportType,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $All
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPPermission
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $TargetName,

        [Parameter()]
        [System.String]
        $TargetType,

        [Parameter()]
        [System.String]
        $DomainName,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $All
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPPrefRegistryValue
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Context,

        [Parameter()]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $ValueName,

        [Parameter()]
        [System.Int32]
        $Order,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPRegistryValue
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $ValueName,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPResultantSetOfPolicy
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Computer,

        [Parameter()]
        [System.String]
        $User,

        [Parameter()]
        [System.String]
        $ReportType,

        [Parameter()]
        [System.String]
        $Path
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-GPStarterGPO
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $All
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Import-GPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $BackupId,

        [Parameter()]
        [System.String]
        $BackupGpoName,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Object]
        $TargetGuid,

        [Parameter()]
        [System.String]
        $TargetName,

        [Parameter()]
        [System.String]
        $MigrationTable,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $CreateIfNeeded,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Invoke-GPUpdate
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Computer,

        [Parameter()]
        [System.String]
        $Target,

        [Parameter()]
        [System.Int32]
        $RandomDelayInMinutes,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $LogOff,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Boot,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Sync,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AsJob
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function New-GPLink
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Target,

        [Parameter()]
        [System.String]
        $LinkEnabled,

        [Parameter()]
        [System.Int32]
        $Order,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.String]
        $Enforced
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function New-GPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.Object]
        $StarterGpoGuid,

        [Parameter()]
        [System.String]
        $StarterGpoName,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function New-GPStarterGPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.String]
        $Name,

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

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-GPLink
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Target,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-GPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $KeepLinks
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-GPPrefRegistryValue
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Context,

        [Parameter()]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $ValueName,

        [Parameter()]
        [System.Int32]
        $Order,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-GPRegistryValue
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $ValueName,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Rename-GPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $TargetName,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Restore-GPO
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $BackupId,

        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $All
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-GPInheritance
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.String]
        $Target,

        [Parameter()]
        [System.String]
        $IsBlocked,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-GPLink
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Target,

        [Parameter()]
        [System.String]
        $LinkEnabled,

        [Parameter()]
        [System.Int32]
        $Order,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.String]
        $Enforced
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-GPPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $PermissionLevel,

        [Parameter()]
        [System.String]
        $TargetName,

        [Parameter()]
        [System.String]
        $TargetType,

        [Parameter()]
        [System.String]
        $DomainName,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $All,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Replace
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-GPPrefRegistryValue
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Context,

        [Parameter()]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $ValueName,

        [Parameter()]
        [System.Object]
        $Value,

        [Parameter()]
        [System.String]
        $Type,

        [Parameter()]
        [System.String]
        $Action,

        [Parameter()]
        [System.Int32]
        $Order,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Disable
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-GPRegistryValue
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Stub of a cmdlet that supports -WhatIf and -Confirm.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.Object]
        $Guid,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Key,

        [Parameter()]
        [System.String[]]
        $ValueName,

        [Parameter()]
        [System.Object]
        $Value,

        [Parameter()]
        [System.String]
        $Type,

        [Parameter()]
        [System.String]
        $Domain,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Additive,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Disable,

        [Parameter()]
        [System.String]
        $ValuePrefix
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}
