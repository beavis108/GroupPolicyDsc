# Localized resources for GroupPolicyDsc.Common

ConvertFrom-StringData @'
    ModuleAvailable = The PowerShell module 'GroupPolicy' is available. (GPDSC0001)
    ModuleNotAvailable = The PowerShell module 'GroupPolicy' is not available. Install the Group Policy Management Console (Windows feature 'GPMC' on Windows Server, RSAT capability 'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0' on Windows clients). (GPDSC0002)
    ImportingModule = Importing the PowerShell module 'GroupPolicy' into the global scope. (GPDSC0003)
    FeatureCmdletNotAvailable = The command 'Install-WindowsFeature' is not available, the Group Policy Management Console can not be installed automatically. (GPDSC0004)
    InstallingFeature = Installing the Windows feature 'GPMC' (Group Policy Management Console). (GPDSC0005)
    InstallFeatureFailed = Failed to install the Windows feature 'GPMC'. Exit code '{0}'. (GPDSC0006)
    InstallFeatureRestartRequired = The installation of the Windows feature 'GPMC' requires a restart of the node. (GPDSC0007)
    GpoQueryFailed = Could not query the Group Policy Object '{0}'. (GPDSC0008)
    StarterGpoQueryFailed = Could not query the Starter GPO '{0}'. (GPDSC0009)
    TargetQueryFailed = Could not read the GPO links of the container '{0}'. (GPDSC0010)
    BackupFileInvalid = The backup information file '{0}' could not be read and is ignored. {1} (GPDSC0011)
    WmiFilterQueryFailed = Could not query the WMI filters of the domain '{0}'. (GPDSC0012)
    InvalidRegistryValue = The value '{0}' can not be converted to the registry value type '{1}'. (GPDSC0013)
    MissingRegistryValue = A value must be specified for the registry value type '{0}'. (GPDSC0014)
    ReportInvalid = The Group Policy report could not be read. (GPDSC0015)
'@
