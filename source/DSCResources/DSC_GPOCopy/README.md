# Description

This resource is used to create a Group Policy Object (GPO) as a copy of
another GPO (`Copy-GPO`), in the same domain or in another domain. A
migration table maps security principals and UNC paths between domains
(`MigrationTable`). `CopyAcl` copies the permissions of the source GPO.

The copy is made once: the resource is in the desired state as soon as a GPO
named `TargetName` exists. Later changes of the source GPO are not copied
again, and the copy can be changed independently.

To keep a GPO synchronized with a reference GPO, back up the reference GPO
with [GPOBackup](GPOBackup) and import the backup with
[GPOImport](GPOImport) in mode `Enforce`.

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The source GPO must exist.
- For a copy across domains a trust between the domains is required, and the
  account the LCM runs as must be able to read the source GPO and to create
  GPOs in the target domain.

## Known issues

- The links of the source GPO are not copied. Use [GPLink](GPLink).
