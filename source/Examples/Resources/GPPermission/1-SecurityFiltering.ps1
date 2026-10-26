<#
    .DESCRIPTION
        This example shows security filtering: the GPO is only applied to
        the members of the group 'Web Servers'. Authenticated Users keep the
        permission to read the GPO (required since MS16-072), but are no
        longer allowed to apply it.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPPermission AuthenticatedUsersRead {
            Name            = 'Web Server Settings'
            TargetName      = 'Authenticated Users'
            TargetType      = 'Group'
            PermissionLevel = 'GpoRead'
        }

        GPPermission WebServersApply {
            Name            = 'Web Server Settings'
            TargetName      = 'Web Servers'
            TargetType      = 'Group'
            PermissionLevel = 'GpoApply'
        }
    }
}
