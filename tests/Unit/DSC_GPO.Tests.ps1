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
    $script:dscResourceName = 'DSC_GPO'

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

Describe 'DSC_GPO\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
    }

    Context 'When the GroupPolicy module is not available' {
        BeforeAll {
            Mock -CommandName Test-GPDscModuleAvailable -MockWith { $false }
            Mock -CommandName Get-GPDscGpo
        }

        It 'Should return Absent without querying the domain' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Get-TargetResource -Name 'Baseline').Ensure | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Get-GPDscGpo -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the GPO exists' {
        BeforeAll {
            Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
            Mock -CommandName Get-GPDscGpo -MockWith {
                [PSCustomObject] @{
                    DisplayName = 'Baseline'
                    Id          = [System.Guid] '11111111-1111-1111-1111-111111111111'
                    Description = 'Server baseline'
                    GpoStatus   = 'UserSettingsDisabled'
                    Owner       = 'CONTOSO\Domain Admins'
                    WmiFilter   = [PSCustomObject] @{ Name = 'Servers' }
                    Computer    = [PSCustomObject] @{ DSVersion = 4; SysvolVersion = 4 }
                    User        = [PSCustomObject] @{ DSVersion = 0; SysvolVersion = 0 }
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'Baseline' -Domain 'contoso.com'

                $result.Ensure | Should -Be 'Present'
                $result.Id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result.Comment | Should -Be 'Server baseline'
                $result.Status | Should -Be 'UserSettingsDisabled'
                $result.WmiFilterName | Should -Be 'Servers'
                $result.Owner | Should -Be 'CONTOSO\Domain Admins'
                $result.ComputerVersion | Should -Be 4
                $result.UserVersion | Should -Be 0
                $result.Domain | Should -Be 'contoso.com'
            }
        }
    }

    Context 'When the GPO does not exist' {
        BeforeAll {
            Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
            Mock -CommandName Get-GPDscGpo
        }

        It 'Should return Absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Get-TargetResource -Name 'Baseline').Ensure | Should -Be 'Absent'
            }
        }
    }
}

Describe 'DSC_GPO\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-TargetResource -MockWith {
            @{
                Ensure        = 'Present'
                Comment       = 'Server baseline'
                Status        = 'AllSettingsEnabled'
                WmiFilterName = ''
            }
        }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'only Ensure'; Parameters = @{}; Expected = $true }
        @{ Case = 'matching values'; Parameters = @{ Comment = 'Server baseline'; Status = 'AllSettingsEnabled'; WmiFilterName = '' }; Expected = $true }
        @{ Case = 'a different comment'; Parameters = @{ Comment = 'Other' }; Expected = $false }
        @{ Case = 'a comment in different casing'; Parameters = @{ Comment = 'server baseline' }; Expected = $false }
        @{ Case = 'a different status'; Parameters = @{ Status = 'AllSettingsDisabled' }; Expected = $false }
        @{ Case = 'a missing WMI filter'; Parameters = @{ WmiFilterName = 'Servers' }; Expected = $false }
        @{ Case = 'Ensure Absent'; Parameters = @{ Ensure = 'Absent' }; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' @Parameters | Should -Be $Expected
        }
    }

    It 'Should return $false when the GroupPolicy module is not available' {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $false }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' | Should -BeFalse
        }
    }
}

Describe 'DSC_GPO\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName New-GPO -MockWith { $script:mockGpo }
        Mock -CommandName Remove-GPO
        Mock -CommandName Rename-GPO -MockWith { $script:mockGpo }
        Mock -CommandName Get-GPDscWmiFilter -MockWith { [PSCustomObject] @{ Name = 'Servers' } }
    }

    BeforeEach {
        $script:mockGpo = [PSCustomObject] @{
            DisplayName = 'Baseline'
            Id          = [System.Guid] '11111111-1111-1111-1111-111111111111'
            Description = ''
            GpoStatus   = 'AllSettingsEnabled'
            WmiFilter   = $null
        }
    }

    Context 'When the GPO does not exist' {
        BeforeAll {
            Mock -CommandName Get-GPDscGpo
            Mock -CommandName Get-GPDscStarterGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Template' } }
        }

        It 'Should create the GPO with comment and Starter GPO' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Comment 'Server baseline' -StarterGpoName 'Template' -Domain 'contoso.com'
            }

            Should -Invoke -CommandName New-GPO -Exactly -Times 1 -Scope It -ParameterFilter {
                $Name -eq 'Baseline' -and $Comment -eq 'Server baseline' -and $StarterGpoName -eq 'Template' -and $Domain -eq 'contoso.com'
            }
        }

        It 'Should throw when the Starter GPO does not exist' {
            Mock -CommandName Get-GPDscStarterGpo

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -Name 'Baseline' -StarterGpoName 'Missing' } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.StarterGpoNotFound -f 'Missing') + '*')
            }

            Should -Invoke -CommandName New-GPO -Exactly -Times 0 -Scope It
        }

        It 'Should not do anything when the GPO should be absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Ensure 'Absent'
            }

            Should -Invoke -CommandName Remove-GPO -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-GPO -Exactly -Times 0 -Scope It
        }

        It 'Should rename the GPO PreviousName instead of creating a new GPO' {
            Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Old baseline' } -MockWith { $script:mockGpo }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -PreviousName 'Old baseline'
            }

            Should -Invoke -CommandName Rename-GPO -Exactly -Times 1 -Scope It -ParameterFilter {
                $TargetName -eq 'Baseline' -and $Guid -eq [System.Guid] '11111111-1111-1111-1111-111111111111'
            }
            Should -Invoke -CommandName New-GPO -Exactly -Times 0 -Scope It
        }

        It 'Should throw instead of creating a second GPO when the renamed GPO can not be read' {
            Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Old baseline' } -MockWith { $script:mockGpo }
            Mock -CommandName Rename-GPO

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -Name 'Baseline' -PreviousName 'Old baseline' } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.RenameGpoFailed -f 'Old baseline', 'Baseline') + '*')
            }

            Should -Invoke -CommandName Get-GPDscGpo -Exactly -Times 2 -Scope It -ParameterFilter { $Name -eq 'Baseline' }
            Should -Invoke -CommandName New-GPO -Exactly -Times 0 -Scope It
        }

        It 'Should throw the correct error when New-GPO fails' {
            Mock -CommandName New-GPO -MockWith { throw 'Access is denied.' }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -Name 'Baseline' } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.CreateGpoFailed -f 'Baseline') + '*')
            }
        }
    }

    Context 'When the GPO exists' {
        BeforeAll {
            Mock -CommandName Get-GPDscGpo -MockWith { $script:mockGpo }
        }

        It 'Should change comment, status and WMI filter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Comment 'New comment' -Status 'UserSettingsDisabled' -WmiFilterName 'Servers'
            }

            $script:mockGpo.Description | Should -Be 'New comment'
            $script:mockGpo.GpoStatus | Should -Be 'UserSettingsDisabled'
            $script:mockGpo.WmiFilter.Name | Should -Be 'Servers'
            Should -Invoke -CommandName New-GPO -Exactly -Times 0 -Scope It
        }

        It 'Should remove the WMI filter for an empty WmiFilterName' {
            $script:mockGpo.WmiFilter = [PSCustomObject] @{ Name = 'Servers' }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -WmiFilterName ''
            }

            $script:mockGpo.WmiFilter | Should -BeNullOrEmpty
            Should -Invoke -CommandName Get-GPDscWmiFilter -Exactly -Times 0 -Scope It
        }

        It 'Should throw when the WMI filter does not exist' {
            Mock -CommandName Get-GPDscWmiFilter

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -Name 'Baseline' -WmiFilterName 'Missing' } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.WmiFilterNotFound -f 'Missing') + '*')
            }
        }

        It 'Should remove the GPO and keep the links when requested' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Ensure 'Absent' -KeepLinks $true
            }

            Should -Invoke -CommandName Remove-GPO -Exactly -Times 1 -Scope It -ParameterFilter { $KeepLinks -eq $true }
        }
    }

    Context 'When a restart is required to install GPMC' {
        BeforeAll {
            Mock -CommandName Assert-GPDscModule -MockWith { $false }
            Mock -CommandName Get-GPDscGpo
        }

        It 'Should stop without changes' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline'
            }

            Should -Invoke -CommandName Get-GPDscGpo -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-GPO -Exactly -Times 0 -Scope It
        }
    }
}
