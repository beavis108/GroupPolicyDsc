# Localized resources for DSC_GPInheritance

ConvertFrom-StringData @'
    GetCurrentState = Getting the Group Policy inheritance of '{0}'. (GPI0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. (GPI0002)
    GetInheritanceFailed = Failed to get the Group Policy inheritance of '{0}'. Only domains and organizational units are supported. (GPI0003)
    InheritanceFound = The inheritance of '{0}' is blocked: '{1}'. (GPI0004)
    TestDesiredState = Determining whether the Group Policy inheritance of '{0}' is in the desired state. (GPI0005)
    InDesiredState = The Group Policy inheritance of '{0}' is in the desired state. (GPI0006)
    NotInDesiredState = The Group Policy inheritance of '{0}' is not in the desired state. Blocked should be '{1}', but is '{2}'. (GPI0007)
    SettingInheritance = Setting the Group Policy inheritance of '{0}' to blocked '{1}'. (GPI0008)
    SetInheritanceFailed = Failed to set the Group Policy inheritance of '{0}'. (GPI0009)
'@
