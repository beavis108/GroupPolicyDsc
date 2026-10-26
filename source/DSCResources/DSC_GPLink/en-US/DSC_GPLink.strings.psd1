# Localized resources for DSC_GPLink

ConvertFrom-StringData @'
    GetCurrentState = Getting the link of the Group Policy Object '{0}' to '{1}'. (GPL0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. The link is reported as absent. (GPL0002)
    GpoNotFound = The Group Policy Object '{0}' does not exist. The link is reported as absent. (GPL0003)
    LinkNotFound = The Group Policy Object '{0}' is not linked to '{1}'. (GPL0004)
    LinkFound = The Group Policy Object '{0}' is linked to '{1}' (enabled: '{2}', enforced: '{3}', order: '{4}'). (GPL0005)
    TestDesiredState = Determining whether the link of the Group Policy Object '{0}' to '{1}' is in the desired state. (GPL0006)
    InDesiredState = The link of the Group Policy Object '{0}' to '{1}' is in the desired state. (GPL0007)
    NotInDesiredState = The link of the Group Policy Object '{0}' to '{1}' is not in the desired state. (GPL0008)
    EnsureMismatch = The link of the Group Policy Object '{0}' to '{1}' should be '{2}', but is '{3}'. (GPL0009)
    PropertyMismatch = The property '{2}' of the link of the Group Policy Object '{0}' to '{1}' should be '{3}', but is '{4}'. (GPL0010)
    GpoRequired = The Group Policy Object '{0}' does not exist. Create the GPO with the resource GPO first. (GPL0011)
    CreatingLink = Linking the Group Policy Object '{0}' to '{1}'. (GPL0012)
    UpdatingLink = Changing the link of the Group Policy Object '{0}' to '{1}' ('{2}'). (GPL0013)
    RemovingLink = Removing the link of the Group Policy Object '{0}' to '{1}'. (GPL0014)
    ChangeLinkFailed = Failed to change the link of the Group Policy Object '{0}' to '{1}'. (GPL0015)
'@
