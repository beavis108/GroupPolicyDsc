# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceName = 'DSC_GPOImport'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Load stub cmdlets.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\GroupPolicy.stubs.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload stub module
    Remove-Module -Name GroupPolicy.stubs -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_GPOImport\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $script:mockBackup = [PSCustomObject] @{
            Id         = 'aaaaaaaa-0000-0000-0000-000000000001'
            GpoId      = '99999999-9999-9999-9999-999999999999'
            GpoName    = 'Baseline'
            BackupTime = [System.DateTime]::new(2026, 3, 1, 10, 0, 0, [System.DateTimeKind]::Utc)
            Path       = 'C:\GPOBackup\{aaaaaaaa-0000-0000-0000-000000000001}'
            ReportPath = 'C:\GPOBackup\{aaaaaaaa-0000-0000-0000-000000000001}\gpreport.xml'
        }

        $script:reportTemplate = '<GPO xmlns="http://www.microsoft.com/GroupPolicy/Settings"><Computer><VersionDirectory>{1}</VersionDirectory><ExtensionData><Extension><Setting>{0}</Setting></Extension><Name>Registry</Name></ExtensionData></Computer><User /></GPO>'

        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPDscBackup -MockWith { $script:mockBackup }
        Mock -CommandName Get-GPDscGpo -MockWith {
            [PSCustomObject] @{
                DisplayName = 'Baseline'
                Id          = [System.Guid] '11111111-1111-1111-1111-111111111111'
                Computer    = [PSCustomObject] @{ DSVersion = 3 }
                User        = [PSCustomObject] @{ DSVersion = 0 }
            }
        }
        Mock -CommandName Get-GPOReport -MockWith { $script:reportTemplate -f 'A', 7 }

        $script:mockBackup.ReportPath = Join-Path -Path $TestDrive -ChildPath 'gpreport.xml'
        Set-Content -Path $script:mockBackup.ReportPath -Value ($script:reportTemplate -f 'A', 2) -Encoding Unicode
    }

    It 'Should return the backup and that the GPO has settings in mode Once' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup'

            $result.BackupId | Should -Be 'aaaaaaaa-0000-0000-0000-000000000001'
            $result.BackupGpoName | Should -Be 'Baseline'
            $result.GpoId | Should -Be '11111111-1111-1111-1111-111111111111'
            $result.HasSettings | Should -BeTrue
            $result.SettingsMatch | Should -BeNullOrEmpty
        }

        Should -Invoke -CommandName Get-GPDscBackup -Exactly -Times 1 -Scope It -ParameterFilter { $GpoName -eq 'Baseline' }
        Should -Invoke -CommandName Get-GPOReport -Exactly -Times 0 -Scope It
    }

    It 'Should select the backup by BackupId' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $null = Get-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -BackupId '{aaaaaaaa-0000-0000-0000-000000000001}'
        }

        Should -Invoke -CommandName Get-GPDscBackup -Exactly -Times 1 -Scope It -ParameterFilter { $BackupId -eq '{aaaaaaaa-0000-0000-0000-000000000001}' }
    }

    It 'Should compare the settings in mode Enforce' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -Mode 'Enforce').SettingsMatch | Should -BeTrue
        }

        Should -Invoke -CommandName Get-GPOReport -Exactly -Times 1 -Scope It -ParameterFilter { $ReportType -eq 'Xml' }
    }

    It 'Should report different settings in mode Enforce' {
        Mock -CommandName Get-GPOReport -MockWith { $script:reportTemplate -f 'B', 7 }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -Mode 'Enforce').SettingsMatch | Should -BeFalse
        }
    }
}

Describe 'DSC_GPOImport\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'a missing GPO'; Mode = 'Once'; State = @{ GpoId = $null; BackupId = 'a'; HasSettings = $false; SettingsMatch = $null }; Expected = $false }
        @{ Case = 'an empty GPO in mode Once'; Mode = 'Once'; State = @{ GpoId = 'g'; BackupId = 'a'; HasSettings = $false; SettingsMatch = $null }; Expected = $false }
        @{ Case = 'a GPO with settings in mode Once'; Mode = 'Once'; State = @{ GpoId = 'g'; BackupId = $null; HasSettings = $true; SettingsMatch = $null }; Expected = $true }
        @{ Case = 'matching settings in mode Enforce'; Mode = 'Enforce'; State = @{ GpoId = 'g'; BackupId = 'a'; HasSettings = $true; SettingsMatch = $true }; Expected = $true }
        @{ Case = 'different settings in mode Enforce'; Mode = 'Enforce'; State = @{ GpoId = 'g'; BackupId = 'a'; HasSettings = $true; SettingsMatch = $false }; Expected = $false }
        @{ Case = 'a missing backup in mode Enforce'; Mode = 'Enforce'; State = @{ GpoId = 'g'; BackupId = $null; HasSettings = $true; SettingsMatch = $null }; Expected = $false }
    ) {
        Mock -CommandName Get-TargetResource -MockWith { $State }

        InModuleScope -Parameters @{ Mode = $Mode; Expected = $Expected } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -Mode $Mode | Should -Be $Expected
        }
    }
}

Describe 'DSC_GPOImport\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $script:mockBackup = [PSCustomObject] @{
            Id         = 'aaaaaaaa-0000-0000-0000-000000000001'
            GpoId      = '99999999-9999-9999-9999-999999999999'
            GpoName    = 'Baseline'
            BackupTime = [System.DateTime]::new(2026, 3, 1, 10, 0, 0, [System.DateTimeKind]::Utc)
            Path       = 'C:\GPOBackup\{aaaaaaaa-0000-0000-0000-000000000001}'
            ReportPath = 'C:\GPOBackup\{aaaaaaaa-0000-0000-0000-000000000001}\gpreport.xml'
        }

        $script:reportTemplate = '<GPO xmlns="http://www.microsoft.com/GroupPolicy/Settings"><Computer><VersionDirectory>{1}</VersionDirectory><ExtensionData><Extension><Setting>{0}</Setting></Extension><Name>Registry</Name></ExtensionData></Computer><User /></GPO>'

        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Get-GPDscBackup -MockWith { $script:mockBackup }
        Mock -CommandName Import-GPO
    }

    It 'Should import the resolved backup and create the GPO if needed' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -MigrationTable 'C:\GPOBackup\contoso.migtable' -Domain 'contoso.com'
        }

        Should -Invoke -CommandName Import-GPO -Exactly -Times 1 -Scope It -ParameterFilter {
            $BackupId -eq 'aaaaaaaa-0000-0000-0000-000000000001' -and
            $TargetName -eq 'Baseline' -and
            $CreateIfNeeded -and
            $MigrationTable -eq 'C:\GPOBackup\contoso.migtable' -and
            $Domain -eq 'contoso.com'
        }
    }

    It 'Should throw when the backup folder does not exist' {
        Mock -CommandName Test-Path -MockWith { $false }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Path 'C:\Missing' } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.PathNotFound -f 'C:\Missing') + '*')
        }
    }

    It 'Should throw when no backup is found' {
        Mock -CommandName Get-GPDscBackup

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -BackupGpoName 'Other' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.BackupNotFound -f 'C:\GPOBackup', '', 'Other') + '*')
        }

        Should -Invoke -CommandName Import-GPO -Exactly -Times 0 -Scope It
    }

    It 'Should throw when the migration table does not exist' {
        Mock -CommandName Test-Path -ParameterFilter { $PathType -eq 'Leaf' } -MockWith { $false }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -MigrationTable 'C:\missing.migtable' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.MigrationTableNotFound -f 'C:\missing.migtable') + '*')
        }
    }

    It 'Should throw the correct error when Import-GPO fails' {
        Mock -CommandName Import-GPO -MockWith { throw 'The data is invalid.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.ImportFailed -f 'aaaaaaaa-0000-0000-0000-000000000001', 'Baseline') + '*')
        }
    }
}
