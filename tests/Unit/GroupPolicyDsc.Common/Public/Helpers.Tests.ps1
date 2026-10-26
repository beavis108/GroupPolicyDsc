[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'GroupPolicyDsc'
    $script:subModuleName = 'GroupPolicyDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    # Load stub cmdlets.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs\ServerManager.stubs.psm1')
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs\GroupPolicy.stubs.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name ServerManager.stubs -Force
    Remove-Module -Name GroupPolicy.stubs -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}

Describe 'Get-GPDscGpoLink' {
    Context 'When the target is an organizational unit' {
        BeforeAll {
            Mock -CommandName Get-GPInheritance -MockWith {
                [PSCustomObject] @{
                    GpoLinks = @(
                        [PSCustomObject] @{ GpoId = '11111111-1111-1111-1111-111111111111'; DisplayName = 'Baseline'; Enabled = $true; Enforced = $false; Order = 1 }
                        [PSCustomObject] @{ GpoId = '22222222-2222-2222-2222-222222222222'; DisplayName = 'Server'; Enabled = $false; Enforced = $true; Order = 2 }
                    )
                }
            }
            Mock -CommandName Get-GPDscSiteGpLink
        }

        It 'Should return the links from Get-GPInheritance' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-GPDscGpoLink -Target 'OU=Servers,DC=contoso,DC=com' -Domain 'contoso.com'

                $result | Should -HaveCount 2
                $result[1].GpoId | Should -Be ([System.Guid] '22222222-2222-2222-2222-222222222222')
                $result[1].DisplayName | Should -Be 'Server'
                $result[1].Enabled | Should -BeFalse
                $result[1].Enforced | Should -BeTrue
                $result[1].Order | Should -Be 2
            }

            Should -Invoke -CommandName Get-GPInheritance -Exactly -Times 1 -Scope It -ParameterFilter {
                $Target -eq 'OU=Servers,DC=contoso,DC=com' -and $Domain -eq 'contoso.com'
            }
            Should -Invoke -CommandName Get-GPDscSiteGpLink -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the target is a site' {
        BeforeAll {
            Mock -CommandName Get-GPInheritance
            Mock -CommandName Get-GPDscSiteGpLink -MockWith {
                '[LDAP://cn={11111111-1111-1111-1111-111111111111},cn=policies,cn=system,DC=contoso,DC=com;2]'
            }
        }

        It 'Should read the attribute gPLink' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-GPDscGpoLink -Target 'CN=Berlin,CN=Sites,CN=Configuration,DC=contoso,DC=com'

                $result | Should -HaveCount 1
                $result[0].Enforced | Should -BeTrue
                $result[0].Order | Should -Be 1
            }

            Should -Invoke -CommandName Get-GPInheritance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the container can not be read' {
        BeforeAll {
            Mock -CommandName Get-GPInheritance -MockWith { throw 'There is no such object on the server.' }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-GPDscGpoLink -Target 'OU=Missing,DC=contoso,DC=com' } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.TargetQueryFailed -f 'OU=Missing,DC=contoso,DC=com') + '*')
            }
        }
    }
}

Describe 'Get-GPDscBackup' {
    BeforeAll {
        function New-TestBackup
        {
            param ($Path, $Id, $GpoId, $GpoName, $BackupTime, $ComputerVersion = 3, $UserVersion = 0, [switch] $NoReport)

            $folder = New-Item -Path (Join-Path -Path $Path -ChildPath ('{{{0}}}' -f $Id)) -ItemType Directory -Force

            @"
<?xml version="1.0" encoding="utf-8"?>
<BackupInst xmlns="http://www.microsoft.com/GroupPolicy/GPOOperations/Manifest">
  <GPOGuid><![CDATA[{$GpoId}]]></GPOGuid>
  <GPODomain><![CDATA[contoso.com]]></GPODomain>
  <BackupTime><![CDATA[$BackupTime]]></BackupTime>
  <ID><![CDATA[{$($Id.ToUpper())}]]></ID>
  <Comment><![CDATA[Nightly]]></Comment>
  <GPODisplayName><![CDATA[$GpoName]]></GPODisplayName>
</BackupInst>
"@ | Set-Content -Path (Join-Path -Path $folder.FullName -ChildPath 'bkupInfo.xml') -Encoding UTF8

            if (-not $NoReport)
            {
                @"
<?xml version="1.0" encoding="utf-16"?>
<GPO xmlns="http://www.microsoft.com/GroupPolicy/Settings">
  <Name>$GpoName</Name>
  <Computer><VersionDirectory>$ComputerVersion</VersionDirectory><VersionSysvol>$ComputerVersion</VersionSysvol><Enabled>true</Enabled></Computer>
  <User><VersionDirectory>$UserVersion</VersionDirectory><VersionSysvol>$UserVersion</VersionSysvol><Enabled>true</Enabled></User>
</GPO>
"@ | Set-Content -Path (Join-Path -Path $folder.FullName -ChildPath 'gpreport.xml') -Encoding Unicode
            }
        }

        $script:backupPath = Join-Path -Path $TestDrive -ChildPath 'GPOBackup'
        $null = New-Item -Path $script:backupPath -ItemType Directory -Force

        New-TestBackup -Path $script:backupPath -Id 'aaaaaaaa-0000-0000-0000-000000000001' -GpoId '11111111-1111-1111-1111-111111111111' -GpoName 'Baseline' -BackupTime '2026-01-01T10:00:00'
        New-TestBackup -Path $script:backupPath -Id 'aaaaaaaa-0000-0000-0000-000000000002' -GpoId '11111111-1111-1111-1111-111111111111' -GpoName 'Baseline' -BackupTime '2026-03-01T10:00:00' -ComputerVersion 5 -UserVersion 2
        New-TestBackup -Path $script:backupPath -Id 'aaaaaaaa-0000-0000-0000-000000000003' -GpoId '22222222-2222-2222-2222-222222222222' -GpoName 'Server' -BackupTime '2026-02-01T10:00:00' -NoReport

        # A folder that is not a backup and a folder with an invalid file are ignored.
        $null = New-Item -Path (Join-Path -Path $script:backupPath -ChildPath 'Scripts') -ItemType Directory -Force
        $invalidFolder = New-Item -Path (Join-Path -Path $script:backupPath -ChildPath '{bbbbbbbb-0000-0000-0000-000000000000}') -ItemType Directory -Force
        'no xml' | Set-Content -Path (Join-Path -Path $invalidFolder.FullName -ChildPath 'bkupInfo.xml')
    }

    It 'Should return all backups, the most recent first' {
        InModuleScope -Parameters @{ BackupPath = $script:backupPath } -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-GPDscBackup -Path $BackupPath

            $result | Should -HaveCount 3
            $result[0].Id | Should -Be 'aaaaaaaa-0000-0000-0000-000000000002'
            $result[0].GpoId | Should -Be '11111111-1111-1111-1111-111111111111'
            $result[0].GpoName | Should -Be 'Baseline'
            $result[0].GpoDomain | Should -Be 'contoso.com'
            $result[0].Comment | Should -Be 'Nightly'
            $result[0].BackupTime | Should -Be ([System.DateTime]::new(2026, 3, 1, 10, 0, 0, [System.DateTimeKind]::Utc))
            $result[0].ComputerVersionDirectory | Should -Be 5
            $result[0].UserVersionSysvol | Should -Be 2
            $result[1].Id | Should -Be 'aaaaaaaa-0000-0000-0000-000000000003'
            $result[1].ReportPath | Should -BeNullOrEmpty
            $result[1].ComputerVersionDirectory | Should -BeNullOrEmpty
        }
    }

    It 'Should filter by <Filter>' -ForEach @(
        @{ Filter = 'GpoName'; Parameters = @{ GpoName = 'Baseline' }; Count = 2 }
        @{ Filter = 'GpoId'; Parameters = @{ GpoId = '{11111111-1111-1111-1111-111111111111}' }; Count = 2 }
        @{ Filter = 'BackupId'; Parameters = @{ BackupId = 'AAAAAAAA-0000-0000-0000-000000000001' }; Count = 1 }
        @{ Filter = 'unknown GPO'; Parameters = @{ GpoName = 'Unknown' }; Count = 0 }
    ) {
        InModuleScope -Parameters @{ BackupPath = $script:backupPath; Filter = $Parameters; Count = $Count } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-GPDscBackup -Path $BackupPath @Filter | Should -HaveCount $Count
        }
    }

    It 'Should return nothing for a missing folder' {
        InModuleScope -Parameters @{ BackupPath = (Join-Path -Path $TestDrive -ChildPath 'Missing') } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-GPDscBackup -Path $BackupPath | Should -HaveCount 0
        }
    }
}

Describe 'Get-GPDscReportSetting' {
    BeforeAll {
        $script:reportA = @'
<?xml version="1.0" encoding="utf-16"?>
<GPO xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.microsoft.com/GroupPolicy/Settings">
  <Identifier><Identifier xmlns="http://www.microsoft.com/GroupPolicy/Types">{11111111-1111-1111-1111-111111111111}</Identifier></Identifier>
  <Name>Baseline</Name>
  <ModifiedTime>2026-01-01T10:00:00</ModifiedTime>
  <Computer>
    <VersionDirectory>3</VersionDirectory>
    <VersionSysvol>3</VersionSysvol>
    <Enabled>true</Enabled>
    <ExtensionData>
      <Extension xmlns:q1="http://www.microsoft.com/GroupPolicy/Settings/Registry" xsi:type="q1:RegistrySettings">
        <q1:Policy><q1:Name>Turn off Autoplay</q1:Name><q1:State>Enabled</q1:State></q1:Policy>
      </Extension>
      <Name>Registry</Name>
    </ExtensionData>
    <ExtensionData>
      <Extension xmlns:q2="http://www.microsoft.com/GroupPolicy/Settings/Security" xsi:type="q2:SecuritySettings">
        <q2:Account><q2:Name>MinimumPasswordLength</q2:Name><q2:SettingNumber>14</q2:SettingNumber></q2:Account>
      </Extension>
      <Name>Security</Name>
    </ExtensionData>
  </Computer>
  <User><VersionDirectory>0</VersionDirectory><VersionSysvol>0</VersionSysvol><Enabled>true</Enabled></User>
  <LinksTo><SOMName>Servers</SOMName></LinksTo>
</GPO>
'@

        # Same settings: different name, versions, times, prefixes, extension order and whitespace.
        $script:reportB = @'
<?xml version="1.0" encoding="utf-16"?>
<GPO xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.microsoft.com/GroupPolicy/Settings">
  <Name>Baseline (imported)</Name>
  <ModifiedTime>2026-05-05T08:00:00</ModifiedTime>
  <Computer>
    <VersionDirectory>7</VersionDirectory>
    <VersionSysvol>7</VersionSysvol>
    <Enabled>false</Enabled>
    <ExtensionData><Extension xmlns:q7="http://www.microsoft.com/GroupPolicy/Settings/Security" xsi:type="q7:SecuritySettings"><q7:Account><q7:Name>MinimumPasswordLength</q7:Name><q7:SettingNumber>14</q7:SettingNumber></q7:Account></Extension><Name>Security</Name></ExtensionData>
    <ExtensionData><Extension xmlns:q3="http://www.microsoft.com/GroupPolicy/Settings/Registry" xsi:type="q3:RegistrySettings"><q3:Policy><q3:Name>Turn off Autoplay</q3:Name><q3:State>Enabled</q3:State></q3:Policy></Extension><Name>Registry</Name></ExtensionData>
  </Computer>
  <User><VersionDirectory>0</VersionDirectory><VersionSysvol>0</VersionSysvol><Enabled>true</Enabled></User>
</GPO>
'@
    }

    It 'Should return the same value for identical settings' {
        InModuleScope -Parameters @{ ReportA = $script:reportA; ReportB = $script:reportB } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-GPDscReportSetting -ReportXml $ReportA | Should -BeExactly (Get-GPDscReportSetting -ReportXml $ReportB)
        }
    }

    It 'Should return a different value when a setting differs' {
        InModuleScope -Parameters @{ ReportA = $script:reportA; ReportB = ($script:reportB -replace '>14<', '>12<') } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-GPDscReportSetting -ReportXml $ReportA | Should -Not -BeExactly (Get-GPDscReportSetting -ReportXml $ReportB)
        }
    }

    It 'Should read a report file' {
        $reportPath = Join-Path -Path $TestDrive -ChildPath 'gpreport.xml'
        Set-Content -Path $reportPath -Value $script:reportB -Encoding Unicode

        InModuleScope -Parameters @{ ReportA = $script:reportA; ReportPath = $reportPath } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-GPDscReportSetting -Path $ReportPath | Should -BeExactly (Get-GPDscReportSetting -ReportXml $ReportA)
        }
    }

    It 'Should throw the correct error for invalid XML' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Get-GPDscReportSetting -ReportXml '<GPO>' } | Should -Throw -ExpectedMessage ('*' + $script:localizedData.ReportInvalid + '*')
        }
    }
}
