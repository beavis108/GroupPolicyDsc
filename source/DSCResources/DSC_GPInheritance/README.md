# Description

This resource is used to block or unblock the inheritance of Group Policy
Objects from parent containers for a domain or an organizational unit
(`Get-GPInheritance`, `Set-GPInheritance`).

When inheritance is blocked, GPOs linked to parent containers are not applied
to the container, except links that are enforced (see the property
`Enforced` of the resource [GPLink](GPLink)).

Every container is a separate resource instance with the distinguished name
of the container as key.

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The container must exist.

## Known issues

- Sites are not supported, because inheritance can not be blocked for a site.
