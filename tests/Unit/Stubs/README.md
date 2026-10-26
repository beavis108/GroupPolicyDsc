# Stubs

A stub function is function with just the skeleton of the original function
or cmdlet. Pester can use a stub function to have something to hook into
when a mock of a cmdlet or function is needed in a unit test. Stub functions
make it possible to run unit tests without having the actual module with
the cmdlet or function installed.

The stubs in this folder are hand-written and contain the parameters of all
26 cmdlets of the module `GroupPolicy` (only the parameters used by the
resources are typed exactly):

- `GroupPolicy.stubs.psm1` - stubs for the Group Policy cmdlets
  (module `GroupPolicy`, feature `GPMC`).
- `ServerManager.stubs.psm1` - stubs for `Get-WindowsFeature` and
  `Install-WindowsFeature` (module `ServerManager`).

## How to regenerate from a Windows Server

Install the module 'Indented.StubCommand' from PowerShell Gallery.

```powershell
Install-Module Indented.StubCommand -Scope CurrentUser
Install-WindowsFeature -Name GPMC
```

```powershell
$functionBody = {
    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

New-StubModule -FromModule 'GroupPolicy' -Path 'tests/Unit/Stubs' -FunctionBody $functionBody
```
