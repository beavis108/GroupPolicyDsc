# Description

This resource is used to configure a registry-based policy setting
(Administrative Template setting) in a Group Policy Object (GPO)
(`Get-GPRegistryValue`, `Set-GPRegistryValue`, `Remove-GPRegistryValue`).

The hive of `Key` decides where the setting is stored: `HKLM` configures the
computer configuration, `HKCU` the user configuration of the GPO.

| Ensure | PolicyState | Result on the clients | Cmdlet |
| --- | --- | --- | --- |
| `Present` | `Set` | The value is set. | `Set-GPRegistryValue -Type -Value` |
| `Present` | `Delete` | The value is deleted. | `Set-GPRegistryValue -Disable` |
| `Absent` | - | The setting is not configured. | `Remove-GPRegistryValue` |

The value is always declared as a string array, so one property can carry
every registry value type. `DWord` and `QWord` values can be decimal or
hexadecimal (`0x` prefix), `Binary` values are hexadecimal bytes (`01 ff`,
`01,ff` or `01ff`) and `MultiString` values are several strings. Values are
compared by their data, not by their spelling, so `0x10` and `16` are equal.

To find the registry key and value of an Administrative Template setting,
use the *Group Policy Settings Reference* spreadsheet or the ADMX file of the
setting.

## Requirements

- Target machine must be a domain member running Windows Server 2012 or
  later (or Windows 10 or later with RSAT).
- The GPO must exist, e.g. created with the resource [GPO](GPO).
- The account the LCM runs as must have the permission `GpoEdit` on the GPO.

## Known issues

- Every change of a setting increases the version of the GPO and makes the
  clients process the GPO again. The resource only changes a setting when it
  differs from the configuration.
- Settings that are not stored in the registry (security settings, scripts,
  software installation) can not be configured with this resource. Use the
  resource [GPOImport](GPOImport) for them.
