# Integration tests

The integration tests apply real configurations with the LCM and create,
change and remove GPOs, links, permissions, backups, a Starter GPO and an
organizational unit in the domain of the test machine.

> [!WARNING]
> Only run the integration tests in a **lab domain**. They need Domain Admin
> rights and change Active Directory and SYSVOL. All objects created by the
> tests start with `GPDscIT` and are removed after each test file - except
> what a failed run leaves behind.

## Requirements

- A domain controller of a lab domain (Windows Server 2016 or later). The
  tests skip themselves on any other machine.
- The environment variable `GPDSC_INTEGRATION_TEST` set to `1`. Without it
  the tests skip themselves, so a build on a production domain controller
  never changes the domain by accident.
- Windows PowerShell 5.1, run as Domain Admin (elevated).
- For the test of `GPStarterGPO` the Starter GPOs folder must exist
  (GPMC > *Starter GPOs* > *Create Starter GPOs Folder*), otherwise that test
  is skipped.

## Run

```powershell
$env:GPDSC_INTEGRATION_TEST = '1'
./build.ps1 -ResolveDependency -Tasks build
./build.ps1 -Tasks test -PesterPath 'tests/Integration' -CodeCoverageThreshold 0
```

A single resource:

```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Integration/DSC_GPLink.Integration.Tests.ps1' -CodeCoverageThreshold 0
```

The tests are not part of the Azure Pipelines build, because hosted build
agents are not domain controllers.

## What the tests verify

Besides the behavior of every resource, the tests verify the assumptions the
resources make about the GroupPolicy module and Active Directory, which unit
tests can not verify:

| Assumption | Verified by |
| --- | --- |
| `Get-GPO` reports a missing GPO with a *not found* error, which is reported as absent | DSC_GPO (`Remove`) |
| `Rename-GPO` keeps the GUID of the GPO | DSC_GPO (`Rename`) |
| In the attribute `gPLink` of a site, a new link gets the highest link order | DSC_GPLink (`Site`) |
| `Set-GPPermission -Replace` lowers a permission (GpoApply to GpoRead) | DSC_GPPermission |
| `(Default)` addresses the default value of a key | DSC_GPRegistryValue |
| DWord, QWord and Binary values are read back as written | DSC_GPRegistryValue |
| Replacing a preference item does not leave a duplicate | DSC_GPPrefRegistryValue (`Change`) |
| Every backup contains `bkupInfo.xml` and `gpreport.xml` | DSC_GPOBackup |
| The version numbers in `gpreport.xml` match the GPO | DSC_GPOBackup |
| The settings in `Get-GPOReport` and `gpreport.xml` compare equal after an import | DSC_GPOImport (`Enforce`) |
| A manual change is detected and reverted in mode `Enforce` | DSC_GPOImport (`Enforce`) |

## Cleanup after a failed run

```powershell
Import-Module ./tests/Integration/GroupPolicyDsc.IntegrationHelper.psm1
Get-GPO -All | Where-Object DisplayName -like 'GPDscIT*' | Remove-GPO -Confirm:$false
Remove-GPDscTestStarterGpo -Name 'GPDscIT Starter'
Remove-GPDscTestOrganizationalUnit
Remove-Item -Path "$env:SystemDrive\GPDscIT" -Recurse -Force
```
