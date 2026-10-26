@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'GroupPolicyDsc.Common.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'e10e34b3-292c-4554-9147-0433861816fa'

    # Author of this module
    Author            = 'Christoph Meyer'

    # Company or vendor of this module
    CompanyName       = 'GroupPolicyDsc contributors'

    # Copyright statement for this module
    Copyright         = 'Copyright the GroupPolicyDsc contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Functions used by the DSC resources in GroupPolicyDsc.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Assert-GPDscModule'
        'ConvertFrom-GPDscGpLink'
        'ConvertTo-GPDscComparableRegistryValue'
        'ConvertTo-GPDscRegistryValue'
        'ConvertTo-GPDscYesNo'
        'Get-GPDscBackup'
        'Get-GPDscConnectionParameter'
        'Get-GPDscGpo'
        'Get-GPDscGpoLink'
        'Get-GPDscReportSetting'
        'Get-GPDscSiteGpLink'
        'Get-GPDscStarterGpo'
        'Get-GPDscWmiFilter'
        'Import-GPDscModule'
        'Install-GPDscManagementTool'
        'Test-GPDscModuleAvailable'
        'Test-GPDscSiteTarget'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
