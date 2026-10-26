# Description

This resource is used to link a Group Policy Object (GPO) to a site, a domain
or an organizational unit, to enable, disable or enforce the link, to set the
link order or to remove the link (`New-GPLink`, `Set-GPLink`,
`Remove-GPLink`).

The links of domains and organizational units are read with
`Get-GPInheritance`. Because `Get-GPInheritance` does not support sites, the
links of a site are read from the attribute `gPLink` of the site object.

Every link is a separate resource instance, so a GPO can be linked to any
number of containers and a container can have any number of links. The link
is identified by the GUID of the GPO, therefore renaming the GPO with the
resource [GPO](GPO) does not break the link.

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The GPO must exist, e.g. created with the resource [GPO](GPO).
- The account the LCM runs as must have the permission *Link GPOs* on the
  target container.

## Known issues

- `Order` is a dynamic value: it changes when other links are added to or
  removed from the same container. Only manage `Order` when all links of the
  container are managed by DSC, and use consecutive values starting at 1.
  Otherwise two resources can change each other's order on every run.
- The site must be given by its distinguished name, e.g.
  `CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=contoso,DC=com`.
