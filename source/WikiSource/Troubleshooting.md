# Troubleshooting

## Get verbose output

All resources write detailed verbose messages. Every message has an ID (for
example `GPL0012`) that makes it easy to search for it in the source code.

```powershell
Start-DscConfiguration -Path .\GroupPolicy -Wait -Verbose -Force
```

To test a resource without a configuration, use `Invoke-DscResource`:

```powershell
Invoke-DscResource -Name GPLink -ModuleName GroupPolicyDsc -Method Test -Verbose -Property @{
    Name   = 'Server Baseline'
    Target = 'OU=Servers,DC=contoso,DC=com'
}
```

## Access is denied

The LCM runs as `SYSTEM` and accesses Active Directory and SYSVOL with the
**computer account** of the node. On a domain controller the computer account
can manage GPOs, on a member server it usually can not.

Use `PsDscRunAsCredential` with an account that has the required permissions
(and encrypt the MOF file with a certificate):

| Task | Required permission |
| --- | --- |
| Create a GPO ([GPO](GPO), [GPOImport](GPOImport), [GPOCopy](GPOCopy)) | Member of *Group Policy Creator Owners* or delegated *Create GPOs* in GPMC |
| Change settings ([GPRegistryValue](GPRegistryValue), [GPPrefRegistryValue](GPPrefRegistryValue), [GPOImport](GPOImport)) | `GpoEdit` on the GPO |
| Change permissions, rename, remove ([GPPermission](GPPermission), [GPO](GPO)) | `GpoEditDeleteModifySecurity` on the GPO |
| Link a GPO, block inheritance ([GPLink](GPLink), [GPInheritance](GPInheritance)) | *Link GPOs* on the site, domain or OU |
| Read backups and migration tables ([GPOImport](GPOImport), [GPOCopy](GPOCopy)) | Read access to the folder for the account the resource runs as |
| Write backups ([GPOBackup](GPOBackup)) | Write access to the backup folder |

## The term 'Get-GPO' is not recognized

The PowerShell module `GroupPolicy` is part of the Group Policy Management
Console. On Windows Server the resources install the feature `GPMC` when it is
missing. On Windows clients install the RSAT capability:

```powershell
Add-WindowsCapability -Online -Name 'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0'
```

In an air-gapped environment, point `Add-WindowsCapability -Source` to the
*Features on Demand* media.

## A GPO is not found although it exists

- The resources identify GPOs by their **display name**. Check the spelling,
  and that no two GPOs share the same display name in the domain.
- Specify `Domain` when the GPO is not in the domain of the node, and
  `Server` when a domain controller in another site has not replicated the
  GPO yet. By default the PDC emulator is contacted.

## Settings are imported on every consistency check

[GPOImport](GPOImport) with `Mode = 'Enforce'` imports the backup again when
the settings of the GPO differ from the backup. This happens permanently when

- a `MigrationTable` changes the imported values - use `Mode = 'Once'`,
- another resource ([GPRegistryValue](GPRegistryValue),
  [GPPrefRegistryValue](GPPrefRegistryValue)) or an administrator changes the
  same GPO.

Compare the settings manually:

```powershell
Get-GPOReport -Name 'Server Baseline' -ReportType Xml -Path .\current.xml
# and the file gpreport.xml in the backup folder
```

## A Registry preference item is replaced on every consistency check

`Set-GPPrefRegistryValue` can not change an existing item, so
[GPPrefRegistryValue](GPPrefRegistryValue) replaces the item when it differs.
When the item is changed in the Group Policy Management Editor (for example
item-level targeting is added), it differs from the configuration and is
replaced again. Manage such items only with DSC, or use
[GPOImport](GPOImport).

## Link order changes back and forth

The link order of a container is shared by all links. When two
[GPLink](GPLink) resources (or a resource and an administrator) want
different orders, they change each other's order on every run. Only manage
`Order` when all links of the container are managed by DSC.

## Verify that the GPO applies

The resources configure the GPO in Active Directory. Whether the clients
apply it depends on links, inheritance, security filtering and WMI filters.
Create a Resultant Set of Policy report on a client:

```powershell
Get-GPResultantSetOfPolicy -Computer 'srv01.contoso.com' -ReportType Html -Path .\rsop.html
Invoke-GPUpdate -Computer 'srv01.contoso.com' -Force -RandomDelayInMinutes 0
```

Since MS16-072 the computer account must be able to **read** a GPO, also when
security filtering targets users. Keep `GpoRead` for *Authenticated Users* or
*Domain Computers* (see [GPPermission](GPPermission)).

## Verify the module in a lab domain

The repository contains integration tests that apply every resource on a
domain controller and verify the behavior of the GroupPolicy cmdlets the
resources depend on. Run them after an update of Windows Server or of the
module, see `tests/Integration/README.md` in the repository.
