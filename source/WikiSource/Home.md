# Welcome to the GroupPolicyDsc wiki

<sup>*GroupPolicyDsc v#.#.#*</sup>

Here you will find all the information you need to make use of the
GroupPolicyDsc DSC resources in the latest release. This includes details of
the resources that are available, current capabilities and known issues, and
information to help plan a DSC based management of Active Directory Group
Policy Objects (GPOs).

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.development.tega.intranetbw.de/ChristophMeyer/GroupPolicyDsc/issues)
for this repository.

## Resources

| Resource | Description |
| --- | --- |
| [GPO](GPO) | Creates, renames or removes a GPO and manages its comment, status and WMI filter. |
| [GPLink](GPLink) | Links a GPO to a site, domain or OU and manages enabled, enforced and link order. |
| [GPInheritance](GPInheritance) | Blocks or unblocks the inheritance of GPOs for a domain or OU. |
| [GPPermission](GPPermission) | Grants, changes or removes the permission of a user, group or computer on a GPO (security filtering, delegation). |
| [GPRegistryValue](GPRegistryValue) | Configures registry-based policy settings (Administrative Templates). |
| [GPPrefRegistryValue](GPPrefRegistryValue) | Configures Registry preference items (Group Policy Preferences). |
| [GPOImport](GPOImport) | Imports a GPO backup into a GPO, once or enforced, with migration tables. |
| [GPOCopy](GPOCopy) | Creates a GPO as copy of another GPO, also across domains. |
| [GPOBackup](GPOBackup) | Keeps a current backup of a GPO in a backup folder. |
| [GPStarterGPO](GPStarterGPO) | Creates a Starter GPO. |

23 of the 26 cmdlets of the PowerShell module `GroupPolicy` are used by the
resources. The three remaining cmdlets are actions or diagnostics without a
desired state - see [Cmdlet coverage](Cmdlet-Coverage) for which resource
uses which cmdlet.

## Deprecated resources

The documentation, examples, unit test, and integration tests have been removed
for these deprecated resources. These resources will be removed
in a future release.

*No deprecated resources*.

If you are upgrading from the module **xGroupPolicy**, read
[Migration from xGroupPolicy](Migration-from-xGroupPolicy).

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name GroupPolicyDsc -Repository PSGallery
```

- Download GroupPolicyDsc from the [PowerShell Gallery](https://www.powershellgallery.com/packages/GroupPolicyDsc/)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

- For offline or air-gapped environments, copy the folder
  `GroupPolicyDsc\<version>` to `$env:ProgramFiles\WindowsPowerShell\Modules`
  on the authoring machine and on every target node (or publish it on your
  pull server).

To confirm installation, run the below command and ensure you see the
GroupPolicyDsc DSC resources available:

```powershell
Get-DscResource -Module GroupPolicyDsc
```

## Prerequisites

### Operating system

The resources manage GPOs of an Active Directory domain. The target node must
be a domain member (or a domain controller) running Windows Server 2012 or
later, or Windows 10 or later with RSAT.

The Group Policy Management Console (Windows feature `GPMC`, which contains
the PowerShell module `GroupPolicy`) does **not** have to be installed in
advance on Windows Server - every resource installs it when it is missing. On
Windows clients install the RSAT capability
`Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0` in advance.

### Permissions

The LCM runs as `SYSTEM` and therefore accesses Active Directory with the
**computer account** of the node. On a domain controller this account has
the required permissions; on a member server it usually has not. Run the
resources with `PsDscRunAsCredential` and an account that is allowed to
create, edit and link GPOs, see [Troubleshooting](Troubleshooting).

### Powershell

The minimum Windows Management Framework (PowerShell) version required is 5.0
or higher, which ships with Windows 10 or Windows Server 2016,
but can also be installed on Windows 7 SP1, Windows 8.1, Windows Server 2012,
and Windows Server 2012 R2.

## Further reading

- [Cmdlet coverage](Cmdlet-Coverage)
- [Troubleshooting](Troubleshooting)
- [Migration from xGroupPolicy](Migration-from-xGroupPolicy)

## Change log

A full list of changes in each version can be found in the [change log](https://github.development.tega.intranetbw.de/ChristophMeyer/GroupPolicyDsc/blob/main/CHANGELOG.md).
