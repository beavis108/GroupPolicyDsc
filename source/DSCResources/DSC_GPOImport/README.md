# Description

This resource is used to import the settings of a GPO backup into a Group
Policy Object (GPO) (`Import-GPO`). The GPO is created when it does not exist
(`-CreateIfNeeded`). A migration table can be used to map security principals
and UNC paths between domains (`MigrationTable`).

The backup is selected by `BackupId` or, when `BackupId` is not specified, as
the most recent backup of the GPO `BackupGpoName` (defaults to `Name`) in the
folder `Path` - the same backup `Import-GPO -BackupGpoName` would use.

| Mode | The backup is imported when ... |
| --- | --- |
| `Once` (default) | the GPO does not exist or contains no settings. Later changes made in GPMC are kept. |
| `Enforce` | the settings of the GPO differ from the backup. Changes made in GPMC are overwritten. |

In mode `Enforce` the settings are compared with `Get-GPOReport -ReportType
Xml` against the report `gpreport.xml` that every backup contains. Only the
settings (extension data) of the computer and user configuration are
compared - not the name, the version, the permissions, the links or the
WMI filter of the GPO.

Links, permissions, status and WMI filter are managed with the resources
[GPLink](GPLink), [GPPermission](GPPermission) and [GPO](GPO).

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The account the LCM runs as must be able to read `Path` and
  `MigrationTable`. The LCM runs as `SYSTEM`, so a network share must grant
  read access to the computer account of the node.
- The account the LCM runs as must be allowed to create and edit GPOs.

## Known issues

- Do not combine `Mode = 'Enforce'` with a `MigrationTable`. The migration
  table changes the imported settings, so they never match the backup and the
  backup is imported on every consistency check. Use `Mode = 'Once'` instead.
- Do not combine `Mode = 'Enforce'` with the resources
  [GPRegistryValue](GPRegistryValue) or
  [GPPrefRegistryValue](GPPrefRegistryValue) on the same GPO - the resources
  would undo each other's changes.
- Every import increases the version of the GPO and makes all clients process
  the GPO again.
