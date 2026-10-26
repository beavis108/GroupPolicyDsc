# Cmdlet coverage

GroupPolicyDsc uses 23 of the 26 cmdlets of the PowerShell module
[GroupPolicy](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/).
The remaining three cmdlets are actions or diagnostics without a desired state
and are deliberately not used (see below). The table shows which resource uses
which cmdlet.

| Cmdlet | Resource | Used for |
| --- | --- | --- |
| `Backup-GPO` | GPOBackup | Back up a GPO when the most recent backup is outdated (`-Comment`) |
| `Copy-GPO` | GPOCopy | Copy a GPO (`-SourceDomain`, `-TargetDomain`, `-MigrationTable`, `-CopyAcl`) |
| `Get-GPInheritance` | GPInheritance, GPLink | Read the inheritance and the links of a domain or OU |
| `Get-GPO` | All resources (via `Get-GPDscGpo`) | Read |
| `Get-GPOReport` | GPOImport | Compare the settings of a GPO with a backup (`Mode = 'Enforce'`) |
| `Get-GPPermission` | GPPermission | Read the permissions of a GPO (`-All`) |
| `Get-GPPrefRegistryValue` | GPPrefRegistryValue | Read |
| `Get-GPRegistryValue` | GPRegistryValue | Read |
| `Get-GPResultantSetOfPolicy` | - | Not used, see below |
| `Get-GPStarterGPO` | GPStarterGPO, GPO | Read; verify `StarterGpoName` before a GPO is created |
| `Import-GPO` | GPOImport | Import a backup (`-BackupId`, `-MigrationTable`, `-CreateIfNeeded`) |
| `Invoke-GPUpdate` | - | Not used, see below |
| `New-GPLink` | GPLink | Create a link (`-LinkEnabled`, `-Enforced`, `-Order`) |
| `New-GPO` | GPO | Create a GPO (`-Comment`, `-StarterGpoName`) |
| `New-GPStarterGPO` | GPStarterGPO | Create a Starter GPO |
| `Remove-GPLink` | GPLink | `Ensure = 'Absent'` |
| `Remove-GPO` | GPO | `Ensure = 'Absent'` (`-KeepLinks`) |
| `Remove-GPPrefRegistryValue` | GPPrefRegistryValue | `Ensure = 'Absent'`; replace an item that differs |
| `Remove-GPRegistryValue` | GPRegistryValue | `Ensure = 'Absent'` |
| `Rename-GPO` | GPO | Rename the GPO `PreviousName` |
| `Restore-GPO` | - | Not used, see below |
| `Set-GPInheritance` | GPInheritance | `IsBlocked` |
| `Set-GPLink` | GPLink | Change `LinkEnabled`, `Enforced` and `Order` |
| `Set-GPPermission` | GPPermission | Set the exact level (`-Replace`); `Ensure = 'Absent'` (`None`) |
| `Set-GPPrefRegistryValue` | GPPrefRegistryValue | Create an item (`-Action`, `-Type`, `-Value`, `-Disable`) |
| `Set-GPRegistryValue` | GPRegistryValue | Set a value; `PolicyState = 'Delete'` (`-Disable`) |

Properties of a GPO that have no cmdlet are set through the GPO object
returned by `Get-GPO`: the comment (`Description`), the GPO status
(`GpoStatus`) and the WMI filter (`WmiFilter`, looked up with the GPMC API
`Microsoft.GroupPolicy.GPDomain.SearchWmiFilters()`). The links of a site are
read from the attribute `gPLink`, because `Get-GPInheritance` does not
support sites.

## Cmdlets that are deliberately not used

### Invoke-GPUpdate

The cmdlet schedules a Group Policy refresh on a computer. This is an action,
not a state - a resource that calls it would refresh the computer on every
consistency check. Clients process changed GPOs automatically (every 90
minutes with a random offset of up to 30 minutes, domain controllers every 5
minutes). To apply a change immediately, run the cmdlet interactively:

```powershell
Invoke-GPUpdate -Computer 'srv01.contoso.com' -Force -RandomDelayInMinutes 0
```

### Get-GPResultantSetOfPolicy

The cmdlet writes a Resultant Set of Policy (RSoP) report for a computer or
user to a file. It is a diagnostic tool without a desired state. Use it to
verify that a configuration applies as expected (see
[Troubleshooting](Troubleshooting)).

### Restore-GPO

The cmdlet restores a GPO in place from one of its own backups, including the
permissions and the WMI filter link, and only in the domain of the backup.
It is a rollback operation: as a DSC resource it would undo every change of
the resources [GPO](GPO), [GPPermission](GPPermission) and
[GPRegistryValue](GPRegistryValue) on the same GPO. The declarative way to
put the settings of a backup into a GPO is [GPOImport](GPOImport), which also
works across domains and with migration tables. To roll back a GPO manually:

```powershell
Restore-GPO -Name 'Server Baseline' -Path '\\fs01\GPOBackup$'
```

## Not used parameters

- `Set-GPRegistryValue -Additive` and `-ValuePrefix` create values with
  generated names (list policies). Configure each value with its own
  GPRegistryValue resource instead.
- `Get-GPO -All`, `Backup-GPO -All`, `Get-GPOReport -All` and
  `Set-GPPermission -All` work on all GPOs of a domain. Every resource manages
  exactly one GPO.
- `New-GPO -StarterGpoGuid`, `Copy-GPO -SourceGuid` and the other `-Guid`
  parameters: the resources identify GPOs by their display name in the
  configuration and use the GUID internally.

## Remote execution

All resources accept `Domain` and `Server`. The cmdlets then manage the GPOs
of that domain through that domain controller (the PDC emulator by default).
The node only needs the Group Policy Management Console and network access to
the domain controllers.
