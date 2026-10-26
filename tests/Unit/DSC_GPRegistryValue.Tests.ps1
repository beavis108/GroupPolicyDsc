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
    $script:dscResourceName = 'DSC_GPRegistryValue'

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

Describe 'DSC_GPRegistryValue\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
    }

    It 'Should return a DWord value as unsigned number' {
        Mock -CommandName Get-GPRegistryValue -MockWith {
            [PSCustomObject] @{ KeyPath = 'Software\Policies\Contoso'; ValueName = 'Level'; PolicyState = 'Set'; Type = 'DWord'; Value = -1; HasValue = $true }
            [PSCustomObject] @{ KeyPath = 'Software\Policies\Contoso\Sub'; FullKeyPath = 'HKEY_LOCAL_MACHINE\Software\Policies\Contoso\Sub' }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level'

            $result.Ensure | Should -Be 'Present'
            $result.PolicyState | Should -Be 'Set'
            $result.Type | Should -Be 'DWord'
            $result.Value | Should -Be @('4294967295')
        }
    }

    It 'Should return the state Delete without type and value' {
        Mock -CommandName Get-GPRegistryValue -MockWith {
            [PSCustomObject] @{ ValueName = 'Level'; PolicyState = 'Delete'; Type = 'String'; Value = $null; HasValue = $true }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level'

            $result.PolicyState | Should -Be 'Delete'
            $result.Type | Should -BeNullOrEmpty
        }
    }

    It 'Should return Absent without an error message when the cmdlet reports the value as not found' {
        Mock -CommandName Get-GPRegistryValue -MockWith {
            throw [System.ArgumentException]::new('The following Group Policy registry setting was not found.', 'keyPath')
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $verboseOutput = Get-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -Verbose 4>&1

            ($verboseOutput | Where-Object -FilterScript { $_ -is [System.Collections.Hashtable] }).Ensure | Should -Be 'Absent'
            $verboseOutput | Where-Object -FilterScript { "$_" -like '*(GPRV0006)*' } | Should -BeNullOrEmpty
        }
    }

    It 'Should return Absent when the value is not configured' {
        Mock -CommandName Get-GPRegistryValue -MockWith { throw 'The following Group Policy registry setting was not found.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level').Ensure | Should -Be 'Absent'
        }
    }

    It 'Should query the default value with an empty value name' {
        Mock -CommandName Get-GPRegistryValue -MockWith {
            [PSCustomObject] @{ ValueName = ''; PolicyState = 'Set'; Type = 'String'; Value = 'Contoso'; HasValue = $true }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName '(Default)').Value | Should -Be @('Contoso')
        }

        Should -Invoke -CommandName Get-GPRegistryValue -Exactly -Times 1 -Scope It -ParameterFilter { $ValueName -eq '' }
    }

    It 'Should match the default value when the cmdlet returns the name (default)' {
        Mock -CommandName Get-GPRegistryValue -MockWith {
            [PSCustomObject] @{ ValueName = '(default)'; PolicyState = 'Set'; Type = 'String'; Value = 'Contoso'; HasValue = $true }
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName '(Default)').Ensure | Should -Be 'Present'
        }
    }

    It 'Should throw for a key outside HKLM and HKCU' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Get-TargetResource -Name 'Baseline' -Key 'HKCR\Contoso' -ValueName 'Level' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.InvalidKey -f 'HKCR\Contoso') + '*')
        }
    }
}

Describe 'DSC_GPRegistryValue\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Present'; PolicyState = 'Set'; Type = 'DWord'; Value = [System.String[]] @('16') } }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'the same decimal value'; Parameters = @{ Type = 'DWord'; Value = @('16') }; Expected = $true }
        @{ Case = 'the same hexadecimal value'; Parameters = @{ Type = 'DWord'; Value = @('0x10') }; Expected = $true }
        @{ Case = 'a different value'; Parameters = @{ Type = 'DWord'; Value = @('1') }; Expected = $false }
        @{ Case = 'a different type'; Parameters = @{ Type = 'QWord'; Value = @('16') }; Expected = $false }
        @{ Case = 'the state Delete'; Parameters = @{ PolicyState = 'Delete' }; Expected = $false }
        @{ Case = 'Ensure Absent'; Parameters = @{ Ensure = 'Absent' }; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' @Parameters | Should -Be $Expected
        }
    }

    It 'Should compare MultiString values in order' {
        Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Present'; PolicyState = 'Set'; Type = 'MultiString'; Value = [System.String[]] @('a', 'b') } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'List' -Type 'MultiString' -Value 'a', 'b' | Should -BeTrue
            Test-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'List' -Type 'MultiString' -Value 'b', 'a' | Should -BeFalse
            Test-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'List' -Type 'MultiString' -Value 'a' | Should -BeFalse
        }
    }

    It 'Should throw when Type is missing' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Test-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -Value '1' } |
                Should -Throw -ExpectedMessage ('*' + $script:localizedData.TypeRequired + '*')
        }
    }
}

Describe 'DSC_GPRegistryValue\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Set-GPRegistryValue
        Mock -CommandName Remove-GPRegistryValue
        Mock -CommandName Get-GPRegistryValue -MockWith { [PSCustomObject] @{ ValueName = 'Level'; PolicyState = 'Set'; Type = 'DWord'; Value = 1 } }
    }

    It 'Should set the value with the converted data' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -Type 'DWord' -Value '0xFFFFFFFF'
        }

        Should -Invoke -CommandName Set-GPRegistryValue -Exactly -Times 1 -Scope It -ParameterFilter {
            $Type -eq 'DWord' -and $Value -eq -1 -and $ValueName -eq 'Level' -and -not $Disable
        }
    }

    It 'Should configure the value to be deleted on the clients' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -PolicyState 'Delete'
        }

        Should -Invoke -CommandName Set-GPRegistryValue -Exactly -Times 1 -Scope It -ParameterFilter {
            $Disable -and -not $PSBoundParameters.ContainsKey('Type')
        }
    }

    It 'Should remove the setting from the GPO' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -Ensure 'Absent'
        }

        Should -Invoke -CommandName Remove-GPRegistryValue -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Set-GPRegistryValue -Exactly -Times 0 -Scope It
    }

    It 'Should not remove a setting that is not configured' {
        Mock -CommandName Get-GPRegistryValue -MockWith { throw 'not found' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -Ensure 'Absent'
        }

        Should -Invoke -CommandName Remove-GPRegistryValue -Exactly -Times 0 -Scope It
    }

    It 'Should throw when the GPO does not exist' {
        Mock -CommandName Get-GPDscGpo

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -Type 'DWord' -Value '1' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.GpoRequired -f 'Baseline') + '*')
        }
    }

    It 'Should throw the correct error when Set-GPRegistryValue fails' {
        Mock -CommandName Set-GPRegistryValue -MockWith { throw 'Access is denied.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -Key 'HKLM\Software\Policies\Contoso' -ValueName 'Level' -Type 'String' -Value 'x' } |
                Should -Throw -ExpectedMessage '*Failed to change the registry-based policy setting*'
        }
    }
}
