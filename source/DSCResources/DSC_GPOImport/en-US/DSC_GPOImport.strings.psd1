# Localized resources for DSC_GPOImport

ConvertFrom-StringData @'
    GetCurrentState = Getting the import state of the Group Policy Object '{0}' from '{1}'. (GPOI0001)
    BackupNotFound = No GPO backup was found in '{0}' (backup ID: '{1}', backed-up GPO: '{2}'). (GPOI0002)
    BackupFound = Using the backup '{0}' of the GPO '{1}' created at '{2}' (UTC). (GPOI0003)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. (GPOI0004)
    GpoNotFound = The Group Policy Object '{0}' does not exist. (GPOI0005)
    GpoFound = The Group Policy Object '{0}' exists (contains settings: '{1}'). (GPOI0006)
    BackupReportMissing = The backup '{0}' contains no file 'gpreport.xml'. The settings can not be compared. (GPOI0007)
    GetReportFailed = Failed to get the settings report of the Group Policy Object '{0}'. (GPOI0008)
    SettingsCompared = The settings of the Group Policy Object '{0}' match the backup '{1}': '{2}'. (GPOI0009)
    TestDesiredState = Determining whether the Group Policy Object '{0}' is in the desired state (mode '{1}'). (GPOI0010)
    GpoMissing = The Group Policy Object '{0}' does not exist and is created by the import. (GPOI0011)
    GpoEmpty = The Group Policy Object '{0}' contains no settings. (GPOI0012)
    BackupMissingForCompare = The settings of the Group Policy Object '{0}' can not be compared, because the backup was not found. (GPOI0013)
    SettingsDiffer = The settings of the Group Policy Object '{0}' differ from the backup '{1}'. (GPOI0014)
    InDesiredState = The Group Policy Object '{0}' is in the desired state. (GPOI0015)
    NotInDesiredState = The Group Policy Object '{0}' is not in the desired state. (GPOI0016)
    PathNotFound = The backup folder '{0}' does not exist or can not be accessed. (GPOI0017)
    MigrationTableNotFound = The migration table '{0}' does not exist or can not be accessed. (GPOI0018)
    ImportingBackup = Importing the backup '{0}' of the GPO '{1}' into the Group Policy Object '{2}'. (GPOI0019)
    ImportFailed = Failed to import the backup '{0}' into the Group Policy Object '{1}'. (GPOI0020)
'@
