# Migration from xGroupPolicy

GroupPolicyDsc 1.0.0 is the successor of the module **xGroupPolicy** 1.0.0.0.
The module was renamed, the two resources were split into resources with one
task each and the schemas were corrected. A configuration written for
xGroupPolicy therefore has to be adjusted once.

## Why the update is recommended

- **xGroupPolicyInheritance never reported the desired state.**
  `Test-TargetResource` compared a property `Target` of a boolean value, so it
  always returned `$false` and `Set-GPInheritance` ran on every consistency
  check.
- **xGroupPolicyImport imported the backup again and again.**
  `Test-TargetResource` failed whenever `SecurityPrincipal` or
  `PermissionLevel` were not specified, and `Set-TargetResource` always called
  `New-GPO`, `New-GPLink`, `Import-GPO` and `Set-GPPermission` - also for a GPO
  that already existed. Every import increases the GPO version and makes all
  clients process the GPO again.
- **Errors were swallowed.** All errors were only written as warnings, so a
  failed import was reported as successful and the LCM never saw a failure.
- **The resources failed on nodes without the Active Directory module.** The
  module `ActiveDirectory` was imported when the resource was loaded, although
  it was never used. GroupPolicyDsc only needs the module `GroupPolicy` and
  installs the Group Policy Management Console when it is missing.
- **Get-TargetResource returned several hashtables** instead of one, which
  broke `Get-DscConfiguration`.
- **The import depended on fixed file names.** The migration table had to be
  named `ALLGPO.migtable`, and the import failed when the backup folder
  contained more than one backup.

## Module

| xGroupPolicy | GroupPolicyDsc |
| --- | --- |
| `Import-DscResource -ModuleName 'xGroupPolicy'` | `Import-DscResource -ModuleName 'GroupPolicyDsc'` |

Both modules can be installed side by side, but a configuration should only use
one of them for the same GPO or container.

## Resources

### xGroupPolicyImport -> GPOImport, GPLink and GPPermission

xGroupPolicyImport created a GPO, imported a backup, linked the GPO and set
one permission. GroupPolicyDsc splits these tasks, so each of them is tested
and changed independently:

| xGroupPolicyImport property | GroupPolicyDsc | Change |
| --- | --- | --- |
| `TargetName` (Key) | GPOImport `Name` (Key) | Renamed. The GPO is created by the import when it does not exist. |
| `Path` (Key) | GPOImport `Path` (Required) | **The folder that contains the backups.** xGroupPolicy used `<Path>\<TargetName>`, so set `Path` to that folder. |
| - | GPOImport `BackupGpoName` / `BackupId` | New. Defaults to the most recent backup of the GPO `Name`. |
| (fixed `<Path>\ALLGPO.migtable`) | GPOImport `MigrationTable` | New, optional, any file name. |
| - | GPOImport `Mode` | New. `Once` (default) or `Enforce`. |
| `Domain` (Key) | `Domain` (Write) of every resource | Optional, defaults to the computer domain. |
| `OU` (Required, array) | GPLink `Target` (Key) | One GPLink resource per container. Sites are supported. |
| `SecurityPrincipal` | GPPermission `TargetName` (Key) | One GPPermission resource per principal. |
| `TargetType` | GPPermission `TargetType` (Required) | Validated (`Computer`, `User`, `Group`). |
| `PermissionLevel` | GPPermission `PermissionLevel` | Validated. `None` is replaced by `Ensure = 'Absent'`. |

Before:

```powershell
xGroupPolicyImport Baseline {
    TargetName        = 'Baseline'
    Path              = 'C:\GPO'
    Domain            = 'contoso.com'
    OU                = 'OU=Servers,DC=contoso,DC=com', 'OU=Clients,DC=contoso,DC=com'
    SecurityPrincipal = 'GPO-Admins'
    PermissionLevel   = 'GpoEditDeleteModifySecurity'
    TargetType        = 'Group'
}
```

After:

```powershell
GPOImport Baseline {
    Name           = 'Baseline'
    Domain         = 'contoso.com'
    Path           = 'C:\GPO\Baseline'
    MigrationTable = 'C:\GPO\ALLGPO.migtable'
}

GPLink BaselineServers {
    Name      = 'Baseline'
    Domain    = 'contoso.com'
    Target    = 'OU=Servers,DC=contoso,DC=com'
    DependsOn = '[GPOImport]Baseline'
}

GPLink BaselineClients {
    Name      = 'Baseline'
    Domain    = 'contoso.com'
    Target    = 'OU=Clients,DC=contoso,DC=com'
    DependsOn = '[GPOImport]Baseline'
}

GPPermission BaselineAdmins {
    Name            = 'Baseline'
    Domain          = 'contoso.com'
    TargetName      = 'GPO-Admins'
    TargetType      = 'Group'
    PermissionLevel = 'GpoEditDeleteModifySecurity'
    DependsOn       = '[GPOImport]Baseline'
}
```

### xGroupPolicyInheritance -> GPInheritance

| xGroupPolicyInheritance property | GPInheritance property | Change |
| --- | --- | --- |
| `OU` (Required, array) | `Target` (Key) | One resource per container. |
| `Domain` (Key) | `Domain` (Write) | Optional, defaults to the computer domain. |
| `IsBlocked` (Key) | `IsBlocked` (Required) | No longer a key. |

In xGroupPolicy the keys `Domain` and `IsBlocked` allowed only one blocked and
one unblocked list per domain. With GroupPolicyDsc every container is a
separate resource instance:

```powershell
foreach ($ou in @('OU=Kiosk,DC=contoso,DC=com', 'OU=Lab,DC=contoso,DC=com'))
{
    GPInheritance "Block_$($ou.Split(',')[0].Substring(3))" {
        Target    = $ou
        IsBlocked = $true
    }
}
```

## New resources

GroupPolicyDsc adds resources for tasks xGroupPolicy did not cover:
[GPO](GPO), [GPRegistryValue](GPRegistryValue),
[GPPrefRegistryValue](GPPrefRegistryValue), [GPOCopy](GPOCopy),
[GPOBackup](GPOBackup) and [GPStarterGPO](GPStarterGPO).
