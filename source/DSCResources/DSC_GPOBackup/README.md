# Description

This resource is used to make sure a current backup of a Group Policy Object
(GPO) exists in a backup folder (`Backup-GPO`).

The resource is in the desired state when the most recent backup of the GPO
in `Path` contains the current version of the GPO. The version numbers of the
computer and user configuration (Active Directory and SYSVOL) are compared
with the versions in the report `gpreport.xml` of the backup. Every change of
a setting increases these numbers, so a new backup is created after every
change of the settings - and only then.

The backups can be imported with the resource [GPOImport](GPOImport), for
example to synchronize a GPO into another domain or as a reference for a
restore.

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The GPO must exist.
- The account the LCM runs as must be able to read the GPO and to write to
  `Path`. The LCM runs as `SYSTEM`, so a network share must grant write
  access to the computer account of the node.

## Known issues

- Old backups are not removed. Remove them with a scheduled task or a
  retention policy of the file server.
- Changes of the permissions, the links or the WMI filter do not change the
  version of the GPO and therefore do not create a new backup.
