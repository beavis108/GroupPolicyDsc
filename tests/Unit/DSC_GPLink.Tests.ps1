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
    $script:dscResourceName = 'DSC_GPLink'

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

Describe 'DSC_GPLink\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Get-GPDscGpoLink -MockWith {
            [PSCustomObject] @{ GpoId = [System.Guid] '22222222-2222-2222-2222-222222222222'; Enabled = $true; Enforced = $false; Order = 1 }
            [PSCustomObject] @{ GpoId = [System.Guid] '11111111-1111-1111-1111-111111111111'; Enabled = $false; Enforced = $true; Order = 2 }
        }
    }

    It 'Should return the link of the GPO' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com'

            $result.Ensure | Should -Be 'Present'
            $result.LinkEnabled | Should -BeFalse
            $result.Enforced | Should -BeTrue
            $result.Order | Should -Be 2
            $result.GpoId | Should -Be '11111111-1111-1111-1111-111111111111'
        }
    }

    It 'Should return Absent when the GPO is not linked' {
        Mock -CommandName Get-GPDscGpoLink

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com').Ensure | Should -Be 'Absent'
        }
    }

    It 'Should return Absent when the GPO does not exist' {
        Mock -CommandName Get-GPDscGpo

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com'

            $result.Ensure | Should -Be 'Absent'
            $result.GpoId | Should -BeNullOrEmpty
        }

        Should -Invoke -CommandName Get-GPDscGpoLink -Exactly -Times 0 -Scope It
    }
}

Describe 'DSC_GPLink\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Present'; LinkEnabled = $true; Enforced = $false; Order = [System.UInt32] 2 } }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'only Ensure'; Parameters = @{}; Expected = $true }
        @{ Case = 'matching values'; Parameters = @{ LinkEnabled = $true; Enforced = $false; Order = 2 }; Expected = $true }
        @{ Case = 'a disabled link'; Parameters = @{ LinkEnabled = $false }; Expected = $false }
        @{ Case = 'an enforced link'; Parameters = @{ Enforced = $true }; Expected = $false }
        @{ Case = 'a different order'; Parameters = @{ Order = 1 }; Expected = $false }
        @{ Case = 'Ensure Absent'; Parameters = @{ Ensure = 'Absent' }; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' @Parameters | Should -Be $Expected
        }
    }
}

Describe 'DSC_GPLink\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName New-GPLink
        Mock -CommandName Set-GPLink
        Mock -CommandName Remove-GPLink
    }

    Context 'When the link does not exist' {
        BeforeAll {
            Mock -CommandName Get-GPDscGpoLink
        }

        It 'Should create the link with the given settings' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' -Enforced $true -Order 1 -Domain 'contoso.com'
            }

            Should -Invoke -CommandName New-GPLink -Exactly -Times 1 -Scope It -ParameterFilter {
                $Guid -eq [System.Guid] '11111111-1111-1111-1111-111111111111' -and
                $Target -eq 'OU=Servers,DC=contoso,DC=com' -and
                $Enforced -eq 'Yes' -and $Order -eq 1 -and -not $PSBoundParameters.ContainsKey('LinkEnabled') -and
                $Domain -eq 'contoso.com'
            }
            Should -Invoke -CommandName Set-GPLink -Exactly -Times 0 -Scope It
        }

        It 'Should not remove a missing link' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' -Ensure 'Absent'
            }

            Should -Invoke -CommandName Remove-GPLink -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the link exists' {
        BeforeAll {
            Mock -CommandName Get-GPDscGpoLink -MockWith {
                [PSCustomObject] @{ GpoId = [System.Guid] '11111111-1111-1111-1111-111111111111'; Enabled = $true; Enforced = $false; Order = 2 }
            }
        }

        It 'Should only change the settings that differ' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' -LinkEnabled $false -Enforced $false -Order 2
            }

            Should -Invoke -CommandName Set-GPLink -Exactly -Times 1 -Scope It -ParameterFilter {
                $LinkEnabled -eq 'No' -and -not $PSBoundParameters.ContainsKey('Enforced') -and -not $PSBoundParameters.ContainsKey('Order')
            }
            Should -Invoke -CommandName New-GPLink -Exactly -Times 0 -Scope It
        }

        It 'Should not call Set-GPLink when nothing differs' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' -LinkEnabled $true
            }

            Should -Invoke -CommandName Set-GPLink -Exactly -Times 0 -Scope It
        }

        It 'Should remove the link' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' -Ensure 'Absent'
            }

            Should -Invoke -CommandName Remove-GPLink -Exactly -Times 1 -Scope It
        }

        It 'Should throw the correct error when Set-GPLink fails' {
            Mock -CommandName Set-GPLink -MockWith { throw 'Access is denied.' }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' -Order 1 } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.ChangeLinkFailed -f 'Baseline', 'OU=Servers,DC=contoso,DC=com') + '*')
            }
        }
    }

    Context 'When the GPO does not exist' {
        BeforeAll {
            Mock -CommandName Get-GPDscGpo
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.GpoRequired -f 'Baseline') + '*')
            }
        }

        It 'Should not throw when the link should be absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -Name 'Baseline' -Target 'OU=Servers,DC=contoso,DC=com' -Ensure 'Absent' } | Should -Not -Throw
            }
        }
    }
}
