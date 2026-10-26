# GroupPolicyDsc

This module contains DSC resources to manage Active Directory Group Policy
Objects (GPOs): GPOs, links, inheritance, permissions, registry-based policy
settings, registry preferences, import, copy, backup and Starter GPOs.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Resources

| Resource | Description |
| --- | --- |
| **GPO** | Creates, renames or removes a GPO; comment, GPO status, WMI filter, Starter GPO. |
| **GPLink** | Links a GPO to a site, domain or OU; enabled, enforced, link order. |
| **GPInheritance** | Blocks or unblocks the inheritance of GPOs for a domain or OU. |
| **GPPermission** | Grants, changes or removes the permission of a user, group or computer on a GPO. |
| **GPRegistryValue** | Registry-based policy settings (Administrative Templates). |
| **GPPrefRegistryValue** | Registry preference items (Group Policy Preferences). |
| **GPOImport** | Imports a GPO backup into a GPO, once or enforced, with migration tables. |
| **GPOCopy** | Creates a GPO as copy of another GPO, also across domains. |
| **GPOBackup** | Keeps a current backup of a GPO in a backup folder. |
| **GPStarterGPO** | Creates a Starter GPO. |

23 of the 26 cmdlets of the PowerShell module `GroupPolicy` are used by the
resources, the remaining three (`Invoke-GPUpdate`,
`Get-GPResultantSetOfPolicy`, `Restore-GPO`) are actions or diagnostics
without a desired state. The wiki page
[Cmdlet coverage](https://github.development.tega.intranetbw.de/ChristophMeyer/GroupPolicyDsc/wiki/Cmdlet-Coverage)
shows which resource uses which cmdlet.

## Requirements

- The target node must be a domain member (or a domain controller) running
  Windows Server 2012 or later, or Windows 10 or later with RSAT.
- Windows Management Framework (PowerShell) 5.0 or later.
- The account the resources run as must be allowed to create, edit and link
  GPOs. The LCM runs as `SYSTEM` and uses the computer account of the node;
  on a member server use `PsDscRunAsCredential`.

> [!NOTE]
> The Group Policy Management Console does not have to be installed in
> advance on Windows Server. Every resource installs the Windows feature
> `GPMC` (which contains the PowerShell module `GroupPolicy`) when it is
> missing. On Windows clients install the RSAT capability
> `Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0` in advance.

## Installation

```powershell
Install-Module -Name GroupPolicyDsc -Repository PSGallery
```

For offline or air-gapped environments copy the folder
`GroupPolicyDsc\<version>` to `$env:ProgramFiles\WindowsPowerShell\Modules`
on the authoring machine and on every target node (or publish it on your
pull server).

```powershell
Get-DscResource -Module GroupPolicyDsc
```

## Quick start

The configuration creates a GPO for web servers, configures two settings,
links the GPO to an OU and applies it only to the group `Web Servers`.

```powershell
configuration WebServerPolicy
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node 'mgmt01.contoso.com' {
        GPO WebServer {
            Name                 = 'Web Server Settings'
            Comment              = 'Managed by DSC.'
            Status               = 'UserSettingsDisabled'
            PsDscRunAsCredential = $Credential
        }

        GPRegistryValue DisableAutoplay {
            Name                 = 'Web Server Settings'
            Key                  = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
            ValueName            = 'NoDriveTypeAutoRun'
            Type                 = 'DWord'
            Value                = '0xFF'
            PsDscRunAsCredential = $Credential
            DependsOn            = '[GPO]WebServer'
        }

        GPPrefRegistryValue AgentServer {
            Name                 = 'Web Server Settings'
            Context              = 'Computer'
            Key                  = 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso\Agent'
            ValueName            = 'Server'
            Type                 = 'String'
            Value                = 'agent.contoso.com'
            PsDscRunAsCredential = $Credential
            DependsOn            = '[GPO]WebServer'
        }

        GPLink WebServer {
            Name                 = 'Web Server Settings'
            Target               = 'OU=Servers,DC=contoso,DC=com'
            PsDscRunAsCredential = $Credential
            DependsOn            = '[GPO]WebServer'
        }

        GPPermission AuthenticatedUsersRead {
            Name                 = 'Web Server Settings'
            TargetName           = 'Authenticated Users'
            TargetType           = 'Group'
            PermissionLevel      = 'GpoRead'
            PsDscRunAsCredential = $Credential
            DependsOn            = '[GPO]WebServer'
        }

        GPPermission WebServersApply {
            Name                 = 'Web Server Settings'
            TargetName           = 'Web Servers'
            TargetType           = 'Group'
            PermissionLevel      = 'GpoApply'
            PsDscRunAsCredential = $Credential
            DependsOn            = '[GPO]WebServer'
        }
    }
}
```

## Design principles

- **One task per resource.** Every resource manages one object (a GPO, a
  link, a permission, a setting) and is tested and changed independently.
- **Idempotent.** `Set-TargetResource` only calls a cmdlet when the current
  state differs from the configuration. No GPO is changed - and no GPO version
  is increased - while the configuration is in the desired state.
- **Errors fail the configuration.** Errors are thrown with localized
  messages and message IDs instead of being written as warnings.
- **No hidden dependencies.** The module `GroupPolicy` is imported on demand
  (the module `ActiveDirectory` is not needed), and GPMC is installed when it
  is missing.

## Upgrading from xGroupPolicy

GroupPolicyDsc replaces the module `xGroupPolicy`. The resources were renamed
and split, so existing configurations have to be adjusted once. See
[Migration from xGroupPolicy](https://github.development.tega.intranetbw.de/ChristophMeyer/GroupPolicyDsc/wiki/Migration-from-xGroupPolicy)
in the wiki for a property-by-property mapping.

| xGroupPolicy | GroupPolicyDsc |
| --- | --- |
| `xGroupPolicyImport` | `GPOImport` + `GPLink` + `GPPermission` |
| `xGroupPolicyInheritance` | `GPInheritance` |

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

To build the module and run the unit tests locally:

```powershell
./build.ps1 -ResolveDependency -Tasks build, test
```

The integration tests change a real domain and only run on a domain
controller of a lab domain, see [tests/Integration](tests/Integration/README.md).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Documentation

The documentation can be found in the [GroupPolicyDsc Wiki](https://github.development.tega.intranetbw.de/ChristophMeyer/GroupPolicyDsc/wiki).
The DSC resource schema files are used to automatically update the
documentation on each PR merge.

### Examples

You can review the [Examples](/source/Examples) directory in the
GroupPolicyDsc module for some general use scenarios for all of the resources
that are in the module.

The resource examples are also available in the [GroupPolicyDsc Wiki](https://github.development.tega.intranetbw.de/ChristophMeyer/GroupPolicyDsc/wiki).
