# Localized resources for DSC_GPPrefRegistryValue

ConvertFrom-StringData @'
    GetCurrentState = Getting the Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}'. (GPPRV0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. The preference item is reported as absent. (GPPRV0002)
    GpoNotFound = The Group Policy Object '{0}' does not exist. The preference item is reported as absent. (GPPRV0003)
    ItemNotFound = No Registry preference item '{0}\\{1}' exists in the {2} configuration of the Group Policy Object '{3}'. (GPPRV0004)
    ItemFound = Found the Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}' with the action '{4}' ({5} item(s)). (GPPRV0005)
    ItemQueryError = The Registry preference item '{0}\\{1}' could not be read and is treated as not configured. {2} (GPPRV0006)
    TestDesiredState = Determining whether the Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}' is in the desired state. (GPPRV0007)
    InDesiredState = The Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}' is in the desired state. (GPPRV0008)
    NotInDesiredState = The Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}' is not in the desired state. (GPPRV0009)
    EnsureMismatch = The Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}' should be '{4}', but is '{5}'. (GPPRV0010)
    DuplicateItems = {4} Registry preference items exist for '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}', but only one is expected. (GPPRV0011)
    PropertyMismatch = The property '{2}' of the Registry preference item '{0}\\{1}' should be '{3}', but is '{4}'. (GPPRV0012)
    TypeRequired = The property Type is required when Ensure is 'Present' and Action is not 'Delete'. (GPPRV0013)
    GpoRequired = The Group Policy Object '{0}' does not exist. Create the GPO with the resource GPO first. (GPPRV0014)
    RemovingItem = Removing the existing Registry preference item(s) '{0}\\{1}' from the {2} configuration of the Group Policy Object '{3}' ({4} item(s)). (GPPRV0015)
    CreatingItem = Creating the Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}' with the action '{4}'. (GPPRV0016)
    ChangeItemFailed = Failed to change the Registry preference item '{0}\\{1}' in the {2} configuration of the Group Policy Object '{3}'. (GPPRV0017)
'@
