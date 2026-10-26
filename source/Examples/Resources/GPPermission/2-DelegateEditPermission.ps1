<#
    .DESCRIPTION
        This example shows how to delegate the editing of a GPO to a group
        and how to remove the permissions of a user.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPPermission GpoEditors {
            Name            = 'Server Baseline'
            TargetName      = 'CONTOSO\GPO-Editors'
            TargetType      = 'Group'
            PermissionLevel = 'GpoEdit'
        }

        GPPermission FormerAdmin {
            Name       = 'Server Baseline'
            TargetName = 'jdoe'
            TargetType = 'User'
            Ensure     = 'Absent'
        }
    }
}
