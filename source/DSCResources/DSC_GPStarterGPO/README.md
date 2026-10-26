# Description

This resource is used to create a Starter GPO (`Get-GPStarterGPO`,
`New-GPStarterGPO`). A Starter GPO is a template of Administrative Template
settings that new GPOs can be created from (see the property
`StarterGpoName` of the resource [GPO](GPO)).

The GroupPolicy module has no cmdlet to change or remove a Starter GPO or to
configure its settings. The resource therefore only makes sure the Starter
GPO exists. Its settings are edited in the Group Policy Management Editor.

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The Starter GPOs folder must exist in SYSVOL. Create it once in GPMC
  (*Starter GPOs* > *Create Starter GPOs Folder*).

## Known issues

- `Comment` is only used when the Starter GPO is created.
- Starter GPOs can not be removed with DSC. Remove them in GPMC.
