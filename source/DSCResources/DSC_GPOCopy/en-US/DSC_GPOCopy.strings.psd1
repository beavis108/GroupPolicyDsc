# Localized resources for DSC_GPOCopy

ConvertFrom-StringData @'
    GetCurrentState = Getting the state of the copy '{0}' of the Group Policy Object '{1}'. (GPOC0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. (GPOC0002)
    TargetNotFound = The Group Policy Object '{0}' does not exist. (GPOC0003)
    TargetFound = The Group Policy Object '{0}' exists ({1}). (GPOC0004)
    SourceNotFound = The source Group Policy Object '{0}' does not exist. (GPOC0005)
    MigrationTableNotFound = The migration table '{0}' does not exist or can not be accessed. (GPOC0006)
    CopyingGpo = Copying the Group Policy Object '{0}' to '{1}'. (GPOC0007)
    CopyFailed = Failed to copy the Group Policy Object '{0}' to '{1}'. (GPOC0008)
    TestDesiredState = Determining whether the Group Policy Object '{0}' exists. (GPOC0009)
    InDesiredState = The Group Policy Object '{0}' exists. (GPOC0010)
    NotInDesiredState = The Group Policy Object '{0}' does not exist and is copied. (GPOC0011)
'@
