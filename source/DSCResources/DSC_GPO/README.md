# Description

This resource is used to create, rename, change or remove a Group Policy
Object (GPO) (`New-GPO`, `Rename-GPO`, `Remove-GPO`).

Besides the GPO itself the resource manages the comment, the GPO status
(which parts of the GPO are enabled) and the WMI filter linked to the GPO.
A new GPO can be created from a Starter GPO (`StarterGpoName`).

When the GPO `Name` does not exist but a GPO named `PreviousName` does, the
existing GPO is renamed instead of creating a new one. The GUID, the links,
the permissions and the settings of the GPO are kept.

The settings of the GPO are managed with the resources
[GPRegistryValue](GPRegistryValue), [GPPrefRegistryValue](GPPrefRegistryValue)
or [GPOImport](GPOImport). Links are managed with [GPLink](GPLink) and
permissions with [GPPermission](GPPermission).

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The account the LCM runs as must be allowed to create GPOs (member of
  *Group Policy Creator Owners* or delegated in GPMC). Use
  `PsDscRunAsCredential` when the computer account has no permission.
- The WMI filter given in `WmiFilterName` must exist in the domain.

## Known issues

- Removing a GPO (`Ensure = 'Absent'`) also removes all links to the GPO in
  the domain unless `KeepLinks` is `$true`.
- `StarterGpoName` is only used when the GPO is created. Changing it later
  has no effect.
