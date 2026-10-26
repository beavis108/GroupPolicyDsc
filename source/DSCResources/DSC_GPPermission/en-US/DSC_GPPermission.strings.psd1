# Localized resources for DSC_GPPermission

ConvertFrom-StringData @'
    GetCurrentState = Getting the permission of '{0}' on the Group Policy Object '{1}'. (GPP0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. The permission is reported as absent. (GPP0002)
    GpoNotFound = The Group Policy Object '{0}' does not exist. The permission is reported as absent. (GPP0003)
    PermissionNotFound = '{0}' has no permission on the Group Policy Object '{1}'. (GPP0004)
    PermissionFound = '{0}' has the permission '{2}' on the Group Policy Object '{1}' (inherited: '{3}'). (GPP0005)
    TestDesiredState = Determining whether the permission of '{0}' on the Group Policy Object '{1}' is in the desired state. (GPP0006)
    InDesiredState = The permission of '{0}' on the Group Policy Object '{1}' is in the desired state. (GPP0007)
    NotInDesiredState = The permission of '{0}' on the Group Policy Object '{1}' is not in the desired state. (GPP0008)
    EnsureMismatch = The permission of '{0}' on the Group Policy Object '{1}' should be '{2}', but is '{3}'. (GPP0009)
    PermissionLevelMismatch = The permission level of '{0}' on the Group Policy Object '{1}' should be '{2}', but is '{3}'. (GPP0010)
    PermissionLevelRequired = The property PermissionLevel is required when Ensure is 'Present'. (GPP0011)
    GpoRequired = The Group Policy Object '{0}' does not exist. Create the GPO with the resource GPO first. (GPP0012)
    SettingPermission = Granting '{0}' the permission '{2}' on the Group Policy Object '{1}'. (GPP0013)
    RemovingPermission = Removing the permissions of '{0}' from the Group Policy Object '{1}'. (GPP0014)
    SetPermissionFailed = Failed to change the permission of '{0}' on the Group Policy Object '{1}'. (GPP0015)
    GetPermissionFailed = Failed to read the permissions of the Group Policy Object with the ID '{0}'. (GPP0016)
'@
