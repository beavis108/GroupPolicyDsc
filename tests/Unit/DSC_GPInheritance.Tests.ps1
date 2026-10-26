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
    $script:dscResourceName = 'DSC_GPInheritance'

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

Describe 'DSC_GPInheritance\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPInheritance -MockWith {
            [PSCustomObject] @{
                GpoInheritanceBlocked = $true
                ContainerType         = 'OU'
                GpoLinks              = @([PSCustomObject] @{ DisplayName = 'Server baseline' })
                InheritedGpoLinks     = @([PSCustomObject] @{ DisplayName = 'Server baseline' }, [PSCustomObject] @{ DisplayName = 'Default Domain Policy' })
            }
        }
    }

    It 'Should return the current inheritance' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Target 'OU=Servers,DC=contoso,DC=com' -IsBlocked $false -Server 'dc01'

            $result.IsBlocked | Should -BeTrue
            $result.ContainerType | Should -Be 'OU'
            $result.GpoLinks | Should -Be @('Server baseline')
            $result.InheritedGpoLinks | Should -HaveCount 2
        }

        Should -Invoke -CommandName Get-GPInheritance -Exactly -Times 1 -Scope It -ParameterFilter { $Server -eq 'dc01' }
    }

    It 'Should throw the correct error when the container can not be read' {
        Mock -CommandName Get-GPInheritance -MockWith { throw 'There is no such object on the server.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Get-TargetResource -Target 'OU=Missing,DC=contoso,DC=com' -IsBlocked $true } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.GetInheritanceFailed -f 'OU=Missing,DC=contoso,DC=com') + '*')
        }
    }
}

Describe 'DSC_GPInheritance\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-TargetResource -MockWith { @{ IsBlocked = $true } }
    }

    It 'Should return <Expected> when IsBlocked is <IsBlocked>' -ForEach @(
        @{ IsBlocked = $true; Expected = $true }
        @{ IsBlocked = $false; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Target 'OU=Servers,DC=contoso,DC=com' -IsBlocked $IsBlocked | Should -Be $Expected
        }
    }

    It 'Should return $false when the GroupPolicy module is not available' {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $false }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Target 'OU=Servers,DC=contoso,DC=com' -IsBlocked $true | Should -BeFalse
        }
    }
}

Describe 'DSC_GPInheritance\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Set-GPInheritance
    }

    It 'Should set IsBlocked to <Expected> for <IsBlocked>' -ForEach @(
        @{ IsBlocked = $true; Expected = 'Yes' }
        @{ IsBlocked = $false; Expected = 'No' }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Target 'OU=Servers,DC=contoso,DC=com' -IsBlocked $IsBlocked -Domain 'contoso.com'
        }

        Should -Invoke -CommandName Set-GPInheritance -Exactly -Times 1 -Scope It -ParameterFilter {
            $Target -eq 'OU=Servers,DC=contoso,DC=com' -and $IsBlocked -eq $Expected -and $Domain -eq 'contoso.com'
        }
    }

    It 'Should throw the correct error when Set-GPInheritance fails' {
        Mock -CommandName Set-GPInheritance -MockWith { throw 'Access is denied.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Target 'OU=Servers,DC=contoso,DC=com' -IsBlocked $true } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.SetInheritanceFailed -f 'OU=Servers,DC=contoso,DC=com') + '*')
        }
    }
}
