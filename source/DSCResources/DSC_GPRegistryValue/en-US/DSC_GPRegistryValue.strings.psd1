# Localized resources for DSC_GPRegistryValue

ConvertFrom-StringData @'
    GetCurrentState = Getting the registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}'. (GPRV0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. The setting is reported as absent. (GPRV0002)
    GpoNotFound = The Group Policy Object '{0}' does not exist. The setting is reported as absent. (GPRV0003)
    ValueNotFound = The registry-based policy setting '{0}\\{1}' is not configured in the Group Policy Object '{2}'. (GPRV0004)
    ValueFound = The registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' has the state '{3}', the type '{4}' and the value '{5}'. (GPRV0005)
    ValueQueryError = The registry-based policy setting '{0}\\{1}' could not be read and is treated as not configured. {2} (GPRV0006)
    TestDesiredState = Determining whether the registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' is in the desired state. (GPRV0007)
    InDesiredState = The registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' is in the desired state. (GPRV0008)
    NotInDesiredState = The registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' is not in the desired state. (GPRV0009)
    EnsureMismatch = The registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' should be '{3}', but is '{4}'. (GPRV0010)
    PropertyMismatch = The property '{2}' of the registry-based policy setting '{0}\\{1}' should be '{3}', but is '{4}'. (GPRV0011)
    TypeRequired = The property Type is required when Ensure is 'Present' and PolicyState is 'Set'. (GPRV0012)
    InvalidKey = The registry key '{0}' is not valid. The key must start with HKLM, HKEY_LOCAL_MACHINE, HKCU or HKEY_CURRENT_USER. (GPRV0013)
    GpoRequired = The Group Policy Object '{0}' does not exist. Create the GPO with the resource GPO first. (GPRV0014)
    SettingValue = Setting the registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' to the type '{3}' and the value '{4}'. (GPRV0015)
    SettingDeleteValue = Configuring the registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' to delete the value on the clients. (GPRV0016)
    RemovingValue = Removing the registry-based policy setting '{0}\\{1}' from the Group Policy Object '{2}'. (GPRV0017)
    ChangeValueFailed = Failed to change the registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}'. (GPRV0018)
    ValueFoundDelete = The registry-based policy setting '{0}\\{1}' of the Group Policy Object '{2}' deletes the value on the clients. (GPRV0019)
'@
