# Localized resources for DSC_GPOBackup

ConvertFrom-StringData @'
    GetCurrentState = Getting the backups of the Group Policy Object '{0}' in '{1}'. (GPOB0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. (GPOB0002)
    GpoNotFound = The Group Policy Object '{0}' does not exist. (GPOB0003)
    NoBackupFound = No backup of the Group Policy Object '{0}' exists in '{1}'. (GPOB0004)
    BackupFound = The most recent backup of the Group Policy Object '{0}' is '{1}' from '{2}' (UTC), current: '{3}'. (GPOB0005)
    TestDesiredState = Determining whether a current backup of the Group Policy Object '{0}' exists in '{1}'. (GPOB0006)
    InDesiredState = A current backup of the Group Policy Object '{0}' exists in '{1}'. (GPOB0007)
    NotInDesiredState = No current backup of the Group Policy Object '{0}' exists in '{1}'. (GPOB0008)
    GpoRequired = The Group Policy Object '{0}' does not exist and can not be backed up. (GPOB0009)
    CreatingFolder = Creating the backup folder '{0}'. (GPOB0010)
    BackingUpGpo = Backing up the Group Policy Object '{0}' to '{1}'. (GPOB0011)
    BackupFailed = Failed to back up the Group Policy Object '{0}' to '{1}'. (GPOB0012)
'@
