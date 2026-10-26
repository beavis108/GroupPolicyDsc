# Description

This resource is used to configure a Registry preference item (Group Policy
Preferences, *Windows Settings\Registry*) in a Group Policy Object (GPO)
(`Get-GPPrefRegistryValue`, `Set-GPPrefRegistryValue`,
`Remove-GPPrefRegistryValue`).

Unlike registry-based policy settings (see [GPRegistryValue](GPRegistryValue))
preference items can write to any registry key and are not removed from the
clients when the GPO no longer applies.

| Action | Result on the clients |
| --- | --- |
| `Create` | Creates the value if it does not exist. |
| `Replace` | Deletes and recreates the value. |
| `Update` | Creates the value or changes its data (default). |
| `Delete` | Deletes the value. |

`Set-GPPrefRegistryValue` always creates a *new* preference item and never
changes an existing one. When the item differs from the configuration, the
resource therefore removes all items of the registry value and creates one
new item. When more than one item exists for the same value, the resource
reports the value as not in the desired state and replaces them with a single
item.

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The GPO must exist, e.g. created with the resource [GPO](GPO).
- The account the LCM runs as must have the permission `GpoEdit` on the GPO.

## Known issues

- Only preference items of registry *values* are supported, items that only
  create a registry key are not.
- Item-level targeting and the options on the tab *Common* can not be
  configured with the GroupPolicy cmdlets. When the resource replaces an
  item, these options are lost. Use [GPOImport](GPOImport) for such items.
- The processing order of the item (`Order`) is only reported. A replaced item
  is added at the end of the list.
