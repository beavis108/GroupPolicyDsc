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
    $script:dscResourceName = 'DSC_GPOBackup'

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

Describe 'DSC_GPOBackup\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith {
            [PSCustomObject] @{
                Id               = [System.Guid] '11111111-1111-1111-1111-111111111111'
                ModificationTime = [System.DateTime]::new(2026, 3, 1, 9, 0, 0, [System.DateTimeKind]::Utc)
                Computer         = [PSCustomObject] @{ DSVersion = 5; SysvolVersion = 5 }
                User             = [PSCustomObject] @{ DSVersion = 2; SysvolVersion = 2 }
            }
        }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'a backup with the same versions'; Versions = @(5, 5, 2, 2); Expected = $true }
        @{ Case = 'a backup with an older computer version'; Versions = @(4, 4, 2, 2); Expected = $false }
        @{ Case = 'a backup with an older user SYSVOL version'; Versions = @(5, 5, 2, 1); Expected = $false }
    ) {
        Mock -CommandName Get-GPDscBackup -MockWith {
            [PSCustomObject] @{
                Id                       = 'aaaaaaaa-0000-0000-0000-000000000001'
                BackupTime               = [System.DateTime]::new(2026, 3, 1, 10, 0, 0, [System.DateTimeKind]::Utc)
                Comment                  = 'Nightly'
                ComputerVersionDirectory = $Versions[0]
                ComputerVersionSysvol    = $Versions[1]
                UserVersionDirectory     = $Versions[2]
                UserVersionSysvol        = $Versions[3]
            }
        }

        InModuleScope -Parameters @{ Expected = $Expected } -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup'

            $result.BackupCurrent | Should -Be $Expected
            $result.LatestBackupId | Should -Be 'aaaaaaaa-0000-0000-0000-000000000001'
            $result.LatestBackupTime | Should -Be '2026-03-01T10:00:00.0000000Z'
            $result.Comment | Should -Be 'Nightly'
        }

        Should -Invoke -CommandName Get-GPDscBackup -Exactly -Times 1 -Scope It -ParameterFilter { $GpoId -eq '11111111-1111-1111-1111-111111111111' }
    }

    It 'Should compare the backup time when the backup has no report' {
        Mock -CommandName Get-GPDscBackup -MockWith {
            [PSCustomObject] @{ Id = 'b'; BackupTime = [System.DateTime]::new(2026, 3, 1, 10, 0, 0, [System.DateTimeKind]::Utc); Comment = ''; ComputerVersionDirectory = $null; UserVersionDirectory = $null }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup').BackupCurrent | Should -BeTrue
        }
    }

    It 'Should return BackupCurrent $false when no backup exists' {
        Mock -CommandName Get-GPDscBackup

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup'

            $result.BackupCurrent | Should -BeFalse
            $result.LatestBackupId | Should -BeNullOrEmpty
        }
    }
}

Describe 'DSC_GPOBackup\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
    }

    It 'Should return <Expected> when the backup is current: <Expected>' -ForEach @(
        @{ Expected = $true }
        @{ Expected = $false }
    ) {
        Mock -CommandName Get-TargetResource -MockWith { @{ BackupCurrent = $Expected } }

        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' | Should -Be $Expected
        }
    }
}

Describe 'DSC_GPOBackup\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName New-Item
        Mock -CommandName Backup-GPO
    }

    It 'Should back up the GPO with the comment' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' -Comment 'DSC' -Domain 'contoso.com'
        }

        Should -Invoke -CommandName Backup-GPO -Exactly -Times 1 -Scope It -ParameterFilter {
            $Guid -eq [System.Guid] '11111111-1111-1111-1111-111111111111' -and $Path -eq 'C:\GPOBackup' -and $Comment -eq 'DSC' -and $Domain -eq 'contoso.com'
        }
        Should -Invoke -CommandName New-Item -Exactly -Times 0 -Scope It
    }

    It 'Should create a missing backup folder' {
        Mock -CommandName Test-Path -MockWith { $false }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup'
        }

        Should -Invoke -CommandName New-Item -Exactly -Times 1 -Scope It -ParameterFilter { $ItemType -eq 'Directory' }
    }

    It 'Should throw when the GPO does not exist' {
        Mock -CommandName Get-GPDscGpo

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.GpoRequired -f 'Baseline') + '*')
        }
    }

    It 'Should throw the correct error when Backup-GPO fails' {
        Mock -CommandName Backup-GPO -MockWith { throw 'Access is denied.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Path 'C:\GPOBackup' } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.BackupFailed -f 'Baseline', 'C:\GPOBackup') + '*')
        }
    }
}
