# Description

This resource is used to grant, change or remove the permission of a user,
group or computer on a Group Policy Object (GPO) (`Get-GPPermission`,
`Set-GPPermission`).

The permission level is always set exactly (`Set-GPPermission -Replace`).
Without `-Replace`, `Set-GPPermission` never lowers an existing higher
permission, so a configuration with `GpoRead` would never remove an
existing `GpoApply`. With `Ensure = 'Absent'` all permissions of the security
principal are removed (`-PermissionLevel None`).

Every security principal is a separate resource instance. A typical use case
is *security filtering*: remove `GpoApply` from *Authenticated Users*, grant
them `GpoRead` (required since MS16-072) and grant `GpoApply` to a group.

| PermissionLevel | Rights in GPMC |
| --- | --- |
| `GpoRead` | Read |
| `GpoApply` | Read, Apply group policy |
| `GpoEdit` | Read, Write, Create/Delete child objects |
| `GpoEditDeleteModifySecurity` | Edit settings, delete, modify security |

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The GPO must exist, e.g. created with the resource [GPO](GPO).
- The account the LCM runs as must have the permission
  `GpoEditDeleteModifySecurity` on the GPO.

## Known issues

- Denied permissions are ignored. They can only be managed in GPMC.
- Inherited permissions can not be removed with `Ensure = 'Absent'`.
- When `PermissionLevel` is reported as `GpoCustom`, the principal has rights
  that do not match one of the levels. The resource replaces them with the
  configured level.
