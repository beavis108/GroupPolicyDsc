<#
    .DESCRIPTION
        This example shows how to keep a GPO in line with a security baseline
        backup (for example the Microsoft Security Compliance Toolkit). The
        backup is imported again whenever the settings of the GPO differ from
        the backup.
#>

configuration Example
{
    Import-DscResource -ModuleName 'GroupPolicyDsc'

    node localhost {

        GPOImport MemberServerBaseline {
            Name          = 'MSFT Windows Server 2025 - Member Server'
            Path          = 'C:\Baselines\Windows Server 2025\GPOs'
            BackupGpoName = 'MSFT Windows Server 2025 - Member Server'
            Mode          = 'Enforce'
        }

        GPLink MemberServerBaseline {
            Name      = 'MSFT Windows Server 2025 - Member Server'
            Target    = 'OU=Servers,DC=contoso,DC=com'
            DependsOn = '[GPOImport]MemberServerBaseline'
        }
    }
}
