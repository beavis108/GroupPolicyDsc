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
    $script:dscResourceName = 'DSC_GPStarterGPO'

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

Describe 'DSC_GPStarterGPO\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
    }

    It 'Should return the Starter GPO' {
        Mock -CommandName Get-GPDscStarterGpo -MockWith { [PSCustomObject] @{ Id = [System.Guid] '11111111-1111-1111-1111-111111111111'; Description = 'Template' } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Server template'

            $result.Id | Should -Be '11111111-1111-1111-1111-111111111111'
            $result.Comment | Should -Be 'Template'
        }
    }

    It 'Should return no ID when the Starter GPO does not exist' {
        Mock -CommandName Get-GPDscStarterGpo

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Server template').Id | Should -BeNullOrEmpty
        }
    }
}

Describe 'DSC_GPStarterGPO\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
    }

    It 'Should return <Expected> for the ID <Id>' -ForEach @(
        @{ Id = '11111111-1111-1111-1111-111111111111'; Expected = $true }
        @{ Id = $null; Expected = $false }
    ) {
        Mock -CommandName Get-TargetResource -MockWith { @{ Id = $Id } }

        InModuleScope -Parameters @{ Expected = $Expected } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Server template' | Should -Be $Expected
        }
    }
}

Describe 'DSC_GPStarterGPO\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName New-GPStarterGPO
    }

    It 'Should create the Starter GPO' {
        Mock -CommandName Get-GPDscStarterGpo

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Server template' -Comment 'Template' -Server 'dc01'
        }

        Should -Invoke -CommandName New-GPStarterGPO -Exactly -Times 1 -Scope It -ParameterFilter {
            $Name -eq 'Server template' -and $Comment -eq 'Template' -and $Server -eq 'dc01'
        }
    }

    It 'Should not create an existing Starter GPO' {
        Mock -CommandName Get-GPDscStarterGpo -MockWith { [PSCustomObject] @{ Id = [System.Guid]::NewGuid() } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Server template'
        }

        Should -Invoke -CommandName New-GPStarterGPO -Exactly -Times 0 -Scope It
    }

    It 'Should throw the correct error when New-GPStarterGPO fails' {
        Mock -CommandName Get-GPDscStarterGpo
        Mock -CommandName New-GPStarterGPO -MockWith { throw 'The system cannot find the path specified.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Server template' } | Should -Throw -ExpectedMessage '*Failed to create the Starter GPO*'
        }
    }
}
