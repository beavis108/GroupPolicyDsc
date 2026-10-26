# Change log for GroupPolicyDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-22

### Added

- Module renamed from `xGroupPolicy` to `GroupPolicyDsc` and restructured to
  follow the DSC Community module layout (Sampler build, `source` folder,
  nested `GroupPolicyDsc.Common` module, `DscResource.Common` 0.24.5, unit
  tests, examples, conceptual help and wiki).
- 23 of the 26 cmdlets of the module `GroupPolicy` are used by the resources
  (see the wiki page *Cmdlet coverage*).
- New resources:
  - `GPO` - create, rename (`PreviousName`) or remove a GPO; comment, GPO
    status, WMI filter and Starter GPO (`New-GPO`, `Rename-GPO`,
    `Remove-GPO`).
  - `GPLink` - link a GPO to a site, domain or OU; enabled, enforced and
    link order (`New-GPLink`, `Set-GPLink`, `Remove-GPLink`).
  - `GPPermission` - permissions on a GPO for security filtering and
    delegation (`Get-GPPermission`, `Set-GPPermission`).
  - `GPRegistryValue` - registry-based policy settings
    (`Get-`/`Set-`/`Remove-GPRegistryValue`).
  - `GPPrefRegistryValue` - Registry preference items
    (`Get-`/`Set-`/`Remove-GPPrefRegistryValue`).
  - `GPOCopy` - copy a GPO, also across domains (`Copy-GPO`).
  - `GPOBackup` - keep a current backup of a GPO (`Backup-GPO`).
  - `GPStarterGPO` - create a Starter GPO (`Get-GPStarterGPO`,
    `New-GPStarterGPO`).
- GPOImport (successor of `xGroupPolicyImport`)
  - Added `BackupId` and `BackupGpoName` to select the backup.
  - Added `MigrationTable` (optional, any file name).
  - Added `Mode`: `Once` imports into a new or empty GPO, `Enforce` imports
    again when the settings differ from the backup (`Get-GPOReport`).
  - The GPO is created by the import when it does not exist
    (`Import-GPO -CreateIfNeeded`).
- GPInheritance (successor of `xGroupPolicyInheritance`)
  - Added the read properties `ContainerType`, `GpoLinks` and
    `InheritedGpoLinks`.
- All resources
  - Added `Server` to contact a specific domain controller.
  - The Windows feature `GPMC` is installed when the module `GroupPolicy` is
    missing.
- Integration tests for all resources (`tests/Integration`). They run on a
  domain controller of a lab domain when `$env:GPDSC_INTEGRATION_TEST` is
  `1` and also verify the assumptions about the GroupPolicy cmdlets
  (error of `Get-GPO` for a missing GPO, link order in `gPLink`, content of
  GPO backups, report comparison of GPOImport).
- GroupPolicyDsc.Common
  - Added `Assert-GPDscModule`, `ConvertFrom-GPDscGpLink`,
    `ConvertTo-GPDscComparableRegistryValue`, `ConvertTo-GPDscRegistryValue`,
    `ConvertTo-GPDscYesNo`, `Get-GPDscBackup`, `Get-GPDscConnectionParameter`,
    `Get-GPDscGpo`, `Get-GPDscGpoLink`, `Get-GPDscReportSetting`,
    `Get-GPDscSiteGpLink`, `Get-GPDscStarterGpo`, `Get-GPDscWmiFilter`,
    `Import-GPDscModule`, `Install-GPDscManagementTool`,
    `Test-GPDscModuleAvailable` and `Test-GPDscSiteTarget`.

### Changed

- BREAKING CHANGE: Resources renamed, split and prefix changed from `MSFT_` to
  `DSC_`:
  - `xGroupPolicyImport` -> `GPOImport` (import), `GPLink` (links) and
    `GPPermission` (permission).
  - `xGroupPolicyInheritance` -> `GPInheritance`.
- BREAKING CHANGE: Schema keys corrected.
  - GPOImport: Key `Name` (was `TargetName`); `Path` is required and is the
    folder that contains the backups (was `<Path>\<TargetName>`); `Domain`
    is optional.
  - GPInheritance: Key `Target` (one container per resource instance, was the
    array `OU`); `IsBlocked` is required (was a key); `Domain` is optional.
- All values with a fixed set of values (`TargetType`, `PermissionLevel`,
  `Status`, `Type`, `Action`, `Context`, `Mode`, `PolicyState`, `Ensure`) are
  validated through a `ValueMap`.
- All verbose and error messages are localized and have a message ID.
- Errors are no longer written as warnings and swallowed - a failing
  `Set-TargetResource` now fails the configuration as expected.
- Module manifest: description corrected (the resources are MOF-based, not
  class-based), explicit exports instead of wildcards, tags, project and
  license URI added, encoding changed from UTF-16 to UTF-8.

### Removed

- The module `ActiveDirectory` is no longer imported (it was never used).
- The functions `Test-xNLBOsRequirement` and `Get-xNLBOsVersion`, which had
  been copied from the module xNLB into `xGroupPolicyCommon`, and the
  duplicate `Get-LocalizedData` (replaced by `DscResource.Common`).

### Fixed

- xGroupPolicyInheritance: `Test-TargetResource` compared the property
  `Target` of a boolean value and therefore always returned `$false`, so
  `Set-GPInheritance` ran on every consistency check.
- xGroupPolicyImport
  - `Test-TargetResource` returned `$false` when `SecurityPrincipal` or
    `PermissionLevel` were not specified, so the backup was imported again on
    every consistency check.
  - `Set-TargetResource` always called `New-GPO` and `New-GPLink`, also for an
    existing GPO or link.
  - The backup ID was read with `Get-ChildItem <Path>\<TargetName>`, which
    failed when the folder contained more than one backup or any other file.
  - The migration table `<Path>\ALLGPO.migtable` was mandatory.
  - `Get-GPO` and `Get-GPInheritance` were called without `-Domain` while the
    other cmdlets used it.
- Both resources: `Get-TargetResource` returned several hashtables instead of
  one, which broke `Get-DscConfiguration`.
