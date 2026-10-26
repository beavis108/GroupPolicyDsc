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
    $script:dscResourceName = 'DSC_GPPermission'

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

Describe 'DSC_GPPermission\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Get-GPPermission -MockWith {
            [PSCustomObject] @{ Trustee = [PSCustomObject] @{ Name = 'Authenticated Users'; Domain = 'NT AUTHORITY' }; TrusteeType = 'WellKnownGroup'; Permission = 'GpoApply'; Inherited = $false; Denied = $false }
            [PSCustomObject] @{ Trustee = [PSCustomObject] @{ Name = 'GPO-Admins'; Domain = 'CONTOSO' }; TrusteeType = 'Group'; Permission = 'GpoEdit'; Inherited = $true; Denied = $false }
            [PSCustomObject] @{ Trustee = [PSCustomObject] @{ Name = 'GPO-Admins'; Domain = 'CONTOSO' }; TrusteeType = 'Group'; Permission = 'GpoEditDeleteModifySecurity'; Inherited = $false; Denied = $false }
            [PSCustomObject] @{ Trustee = [PSCustomObject] @{ Name = 'Guests'; Domain = 'CONTOSO' }; TrusteeType = 'Group'; Permission = 'GpoApply'; Inherited = $false; Denied = $true }
        }
    }

    It 'Should return the permission of <TargetName>' -ForEach @(
        @{ TargetName = 'Authenticated Users'; Expected = 'GpoApply' }
        @{ TargetName = 'GPO-Admins'; Expected = 'GpoEditDeleteModifySecurity' }
        @{ TargetName = 'CONTOSO\GPO-Admins'; Expected = 'GpoEditDeleteModifySecurity' }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -Name 'Baseline' -TargetName $TargetName -TargetType 'Group'

            $result.Ensure | Should -Be 'Present'
            $result.PermissionLevel | Should -Be $Expected
            $result.Inherited | Should -BeFalse
        }
    }

    It 'Should ignore denied permissions' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -Name 'Baseline' -TargetName 'Guests' -TargetType 'Group').Ensure | Should -Be 'Absent'
        }
    }

    It 'Should pass the domain as DomainName' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $null = Get-TargetResource -Name 'Baseline' -TargetName 'GPO-Admins' -TargetType 'Group' -Domain 'contoso.com'
        }

        Should -Invoke -CommandName Get-GPPermission -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -eq 'contoso.com' -and $All }
    }
}

Describe 'DSC_GPPermission\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Present'; PermissionLevel = 'GpoApply' } }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'the same level'; Parameters = @{ PermissionLevel = 'GpoApply' }; Expected = $true }
        @{ Case = 'a lower level'; Parameters = @{ PermissionLevel = 'GpoRead' }; Expected = $false }
        @{ Case = 'Ensure Absent'; Parameters = @{ Ensure = 'Absent' }; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -Name 'Baseline' -TargetName 'Authenticated Users' -TargetType 'Group' @Parameters | Should -Be $Expected
        }
    }

    It 'Should throw when PermissionLevel is missing' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Test-TargetResource -Name 'Baseline' -TargetName 'GPO-Admins' -TargetType 'Group' } |
                Should -Throw -ExpectedMessage ('*' + $script:localizedData.PermissionLevelRequired + '*')
        }
    }
}

Describe 'DSC_GPPermission\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-GPDscModule -MockWith { $true }
        Mock -CommandName Get-GPDscGpo -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid] '11111111-1111-1111-1111-111111111111' } }
        Mock -CommandName Set-GPPermission
    }

    It 'Should set the exact permission level with -Replace' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -TargetName 'Authenticated Users' -TargetType 'Group' -PermissionLevel 'GpoRead' -Domain 'contoso.com'
        }

        Should -Invoke -CommandName Set-GPPermission -Exactly -Times 1 -Scope It -ParameterFilter {
            $PermissionLevel -eq 'GpoRead' -and $Replace -and $TargetType -eq 'Group' -and $DomainName -eq 'contoso.com'
        }
    }

    It 'Should remove the permission with the level None' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -Name 'Baseline' -TargetName 'Helpdesk' -TargetType 'Group' -Ensure 'Absent'
        }

        Should -Invoke -CommandName Set-GPPermission -Exactly -Times 1 -Scope It -ParameterFilter {
            $PermissionLevel -eq 'None' -and -not $Replace
        }
    }

    It 'Should throw when the GPO does not exist' {
        Mock -CommandName Get-GPDscGpo

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -TargetName 'Helpdesk' -TargetType 'Group' -PermissionLevel 'GpoRead' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.GpoRequired -f 'Baseline') + '*')
        }
    }

    It 'Should throw the correct error when Set-GPPermission fails' {
        Mock -CommandName Set-GPPermission -MockWith { throw 'Trustee could not be found.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -Name 'Baseline' -TargetName 'Missing' -TargetType 'Group' -PermissionLevel 'GpoRead' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.SetPermissionFailed -f 'Missing', 'Baseline') + '*')
        }
    }
}
