# Localized resources for DSC_GPStarterGPO

ConvertFrom-StringData @'
    GetCurrentState = Getting the Starter GPO '{0}'. (GPSG0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. (GPSG0002)
    StarterGpoNotFound = The Starter GPO '{0}' does not exist. (GPSG0003)
    StarterGpoFound = Found the Starter GPO '{0}' with the ID '{1}'. (GPSG0004)
    TestDesiredState = Determining whether the Starter GPO '{0}' exists. (GPSG0005)
    InDesiredState = The Starter GPO '{0}' exists. (GPSG0006)
    NotInDesiredState = The Starter GPO '{0}' does not exist. (GPSG0007)
    CreatingStarterGpo = Creating the Starter GPO '{0}'. (GPSG0008)
    CreateStarterGpoFailed = Failed to create the Starter GPO '{0}'. Make sure the Starter GPOs folder exists in SYSVOL (GPMC > Starter GPOs > Create Starter GPOs Folder). (GPSG0009)
'@
