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
    $script:dscResourceName = 'DSC_GPPrefRegistryValue'

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

Describe 'DSC_GPPrefRegistryValue\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
    }

    It 'Should return the item with the highest order' {
        Mock -CommandName Get-GPPrefRegistryValue -MockWith {
            [PSCustomObject] @{ ValueName = 'Server'; Action = 'Create'; Order = 1; DisabledDirectly = $false; Type = 'String'; Value = 'old'; HasValue = $true }
            [PSCustomObject] @{ ValueName = 'Server'; Action = 'Update'; Order = 3; DisabledDirectly = $true; Type = 'String'; Value = 'srv01'; HasValue = $true }
            [PSCustomObject] @{ ValueName = 'Other'; Action = 'Update'; Order = 2; DisabledDirectly = $false; Type = 'String'; Value = 'x'; HasValue = $true }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Server'

            $result.Ensure | Should -Be 'Present'
            $result.ItemCount | Should -Be 2
            $result.Action | Should -Be 'Update'
            $result.Disabled | Should -BeTrue
            $result.Order | Should -Be 3
            $result.Value | Should -Be @('srv01')
        }
    }

    It 'Should return Absent without an error message when the cmdlet reports the item as not found' {
        Mock -CommandName Get-GPPrefRegistryValue -MockWith {
            throw [System.ArgumentException]::new('The Preference registry setting was not found.', 'keyPath')
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $verboseOutput = Get-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Server' -Verbose 4>&1

            ($verboseOutput | Where-Object -FilterScript { $_ -is [System.Collections.Hashtable] }).Ensure | Should -Be 'Absent'
            $verboseOutput | Where-Object -FilterScript { "$_" -like '*(GPPRV0006)*' } | Should -BeNullOrEmpty
        }
    }

    It 'Should return Absent when no item exists' {
        Mock -CommandName Get-GPPrefRegistryValue -MockWith { throw 'not found' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Context 'User' -Key 'HKEY_CURRENT_USER\SOFTWARE\Contoso' -ValueName 'Server'

            $result.Ensure | Should -Be 'Absent'
            $result.ItemCount | Should -Be 0
        }
    }
}

Describe 'DSC_GPPrefRegistryValue\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-TargetResource -MockWith {
            @{ Ensure = 'Present'; ItemCount = 1; Action = 'Update'; Disabled = $false; Type = 'String'; Value = [System.String[]] @('srv01') }
        }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'the same item'; Parameters = @{ Type = 'String'; Value = 'srv01' }; Expected = $true }
        @{ Case = 'a different value'; Parameters = @{ Type = 'String'; Value = 'srv02' }; Expected = $false }
        @{ Case = 'a different action'; Parameters = @{ Action = 'Replace'; Type = 'String'; Value = 'srv01' }; Expected = $false }
        @{ Case = 'a disabled item'; Parameters = @{ Disabled = $true; Type = 'String'; Value = 'srv01' }; Expected = $false }
        @{ Case = 'Ensure Absent'; Parameters = @{ Ensure = 'Absent' }; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Server' @Parameters | Should -Be $Expected
        }
    }

    It 'Should return $false when duplicate items exist' {
        Mock -CommandName Get-TargetResource -MockWith {
            @{ Ensure = 'Present'; ItemCount = 2; Action = 'Update'; Disabled = $false; Type = 'String'; Value = [System.String[]] @('srv01') }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Server' -Type 'String' -Value 'srv01' | Should -BeFalse
        }
    }

    It 'Should not require Type for the action Delete' {
        Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Present'; ItemCount = 1; Action = 'Delete'; Disabled = $false; Type = ''; Value = [System.String[]] @() } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Server' -Action 'Delete' | Should -BeTrue
        }
    }

    It 'Should throw when Type is missing' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Test-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Server' -Value 'x' } |
                Should -Throw -ExpectedMessage ('*' + $script:localizedData.TypeRequired + '*')
        }
    }
}

Describe 'DSC_GPPrefRegistryValue\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Set-GPPrefRegistryValue
        Mock -CommandName Remove-GPPrefRegistryValue
    }

    It 'Should create a new item when none exists' {
        Mock -CommandName Get-GPPrefRegistryValue -MockWith { throw 'not found' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Port' -Type 'DWord' -Value '443' -Disabled $true
        }

        Should -Invoke -CommandName Remove-GPPrefRegistryValue -Exactly -Times 0 -Scope It
        Should -Invoke -CommandName Set-GPPrefRegistryValue -Exactly -Times 1 -Scope It -ParameterFilter {
            $Action -eq 'Update' -and $Type -eq 'DWord' -and $Value -eq 443 -and $Disable -and $Context -eq 'Computer'
        }
    }

    It 'Should replace existing items' {
        Mock -CommandName Get-GPPrefRegistryValue -MockWith {
            [PSCustomObject] @{ ValueName = 'Port'; Action = 'Update'; Order = 1; DisabledDirectly = $false; Type = 'DWord'; Value = 80; HasValue = $true }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Port' -Type 'DWord' -Value '443'
        }

        Should -Invoke -CommandName Remove-GPPrefRegistryValue -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Set-GPPrefRegistryValue -Exactly -Times 1 -Scope It -ParameterFilter { -not $Disable }
    }

    It 'Should only remove the items when the item should be absent' {
        Mock -CommandName Get-GPPrefRegistryValue -MockWith {
            [PSCustomObject] @{ ValueName = 'Port'; Action = 'Update'; Order = 1; DisabledDirectly = $false; Type = 'DWord'; Value = 80; HasValue = $true }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Context 'Computer' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueName 'Port' -Ensure 'Absent'
        }

        Should -Invoke -CommandName Remove-GPPrefRegistryValue -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Set-GPPrefRegistryValue -Exactly -Times 0 -Scope It
    }

    It 'Should throw the correct error when Set-GPPrefRegistryValue fails' {
        Mock -CommandName Get-GPPrefRegistryValue -MockWith { throw 'not found' }
        Mock -CommandName Set-GPPrefRegistryValue -MockWith { throw 'Access is denied.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Context 'User' -Key 'HKEY_CURRENT_USER\SOFTWARE\Contoso' -ValueName 'Port' -Type 'String' -Value 'x' } |
                Should -Throw -ExpectedMessage '*Failed to change the Registry preference item*'
        }
    }
}
