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
    $script:dscResourceName = 'DSC_GPOCopy'

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

Describe 'DSC_GPOCopy\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Baseline' } -MockWith { [PSCustomObject] @{ Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Baseline Copy' }
    }

    It 'Should return the source and that the target does not exist' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -TargetName 'Baseline Copy' -SourceName 'Baseline' -SourceDomain 'test.contoso.com'

            $result.SourceGpoId | Should -Be '11111111-1111-1111-1111-111111111111'
            $result.TargetGpoId | Should -BeNullOrEmpty
        }

        Should -Invoke -CommandName Get-GPDscGpo -Exactly -Times 1 -Scope It -ParameterFilter { $Name -eq 'Baseline' -and $Domain -eq 'test.contoso.com' }
    }
}

Describe 'DSC_GPOCopy\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
    }

    It 'Should return $true when the target exists' {
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ Id = [System.Guid]::NewGuid() } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -TargetName 'Baseline Copy' -SourceName 'Baseline' | Should -BeTrue
        }
    }

    It 'Should return $false when the target does not exist' {
        Mock -CommandName Get-GPDscGpo

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -TargetName 'Baseline Copy' -SourceName 'Baseline' | Should -BeFalse
        }
    }
}

Describe 'DSC_GPOCopy\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Copy-GPO
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Baseline' } -MockWith { [PSCustomObject] @{ Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Baseline Copy' }
    }

    It 'Should copy the GPO across domains' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -TargetName 'Baseline Copy' -SourceName 'Baseline' -SourceDomain 'test.contoso.com' -TargetDomain 'contoso.com' -TargetServer 'dc01' -MigrationTable 'C:\test-to-prod.migtable' -CopyAcl $true
        }

        Should -Invoke -CommandName Copy-GPO -Exactly -Times 1 -Scope It -ParameterFilter {
            $SourceGuid -eq [System.Guid] '11111111-1111-1111-1111-111111111111' -and
            $TargetName -eq 'Baseline Copy' -and
            $SourceDomain -eq 'test.contoso.com' -and
            $TargetDomain -eq 'contoso.com' -and
            $TargetDomainController -eq 'dc01' -and
            -not $PSBoundParameters.ContainsKey('SourceDomainController') -and
            $MigrationTable -eq 'C:\test-to-prod.migtable' -and
            $CopyAcl
        }
    }

    It 'Should not copy when the target already exists' {
        Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Baseline Copy' } -MockWith { [PSCustomObject] @{ Id = [System.Guid]::NewGuid() } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -TargetName 'Baseline Copy' -SourceName 'Baseline'
        }

        Should -Invoke -CommandName Copy-GPO -Exactly -Times 0 -Scope It
    }

    It 'Should throw when the source GPO does not exist' {
        Mock -CommandName Get-GPDscGpo -ParameterFilter { $Name -eq 'Missing' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -TargetName 'Baseline Copy' -SourceName 'Missing' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.SourceNotFound -f 'Missing') + '*')
        }
    }

    It 'Should throw when the migration table does not exist' {
        Mock -CommandName Test-Path -MockWith { $false }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -TargetName 'Baseline Copy' -SourceName 'Baseline' -MigrationTable 'C:\missing.migtable' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.MigrationTableNotFound -f 'C:\missing.migtable') + '*')
        }
    }
}
