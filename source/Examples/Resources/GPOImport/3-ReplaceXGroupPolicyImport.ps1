<#
    .DESCRIPTION
        This example shows the GroupPolicyDsc equivalent of the resource
        xGroupPolicyImport of the module xGroupPolicy: the GPO is created and
        imported from a backup, linked to two organizational units and the
        group 'GPO-Admins' gets the permission to edit the GPO. The resources
        run with a domain account, because the computer account of the node
        is usually not allowed to create GPOs.
#>

configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPOImport Baseline {
            Name                 = 'Baseline'
            Domain               = 'contoso.com'
            Path                 = 'C:\GPO\Baseline'
            MigrationTable       = 'C:\GPO\ALLGPO.migtable'
            PsDscRunAsCredential = $Credential
        }

        foreach ($ou in @('OU=Servers,DC=contoso,DC=com', 'OU=Clients,DC=contoso,DC=com'))
        {
            GPLink "Baseline_$($ou.Split(',')[0].Substring(3))" {
                Name                 = 'Baseline'
                Domain               = 'contoso.com'
                Target               = $ou
                PsDscRunAsCredential = $Credential
                DependsOn            = '[GPOImport]Baseline'
            }
        }

        GPPermission BaselineAdmins {
            Name                 = 'Baseline'
            Domain               = 'contoso.com'
            TargetName           = 'GPO-Admins'
            TargetType           = 'Group'
            PermissionLevel      = 'GpoEditDeleteModifySecurity'
            PsDscRunAsCredential = $Credential
            DependsOn            = '[GPOImport]Baseline'
        }
    }
}
