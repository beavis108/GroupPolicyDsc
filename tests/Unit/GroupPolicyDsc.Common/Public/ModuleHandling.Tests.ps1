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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:subModuleName = 'GroupPolicyDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    # Load stub cmdlets.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs\ServerManager.stubs.psm1')
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs\GroupPolicy.stubs.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name ServerManager.stubs -Force
    Remove-Module -Name GroupPolicy.stubs -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}

Describe 'Test-GPDscModuleAvailable' {
    It 'Should return <Expected> when the module is <State>' -ForEach @(
        @{ State = 'available'; Module = [PSCustomObject] @{ Name = 'GroupPolicy' }; Expected = $true }
        @{ State = 'missing'; Module = $null; Expected = $false }
    ) {
        Mock -CommandName Get-Module -MockWith { $Module }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-GPDscModuleAvailable
        } | Should -Be $Expected
    }
}

Describe 'Import-GPDscModule' {
    Context 'When the module is already imported' {
        BeforeAll {
            Mock -CommandName Get-Module -ParameterFilter { -not $ListAvailable } -MockWith { [PSCustomObject] @{ Name = 'GroupPolicy' } }
            Mock -CommandName Import-Module
        }

        It 'Should not import the module again' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Import-GPDscModule
            }

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the module is available but not imported' {
        BeforeAll {
            Mock -CommandName Get-Module -ParameterFilter { -not $ListAvailable }
            Mock -CommandName Get-Module -ParameterFilter { $ListAvailable } -MockWith { [PSCustomObject] @{ Name = 'GroupPolicy' } }
            Mock -CommandName Import-Module
        }

        It 'Should import the module globally' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Import-GPDscModule
            }

            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It -ParameterFilter {
                $Name -eq 'GroupPolicy' -and $Global -eq $true
            }
        }
    }

    Context 'When the module is not available' {
        BeforeAll {
            Mock -CommandName Get-Module
            Mock -CommandName Import-Module
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Import-GPDscModule } | Should -Throw -ExpectedMessage ('*' + $script:localizedData.ModuleNotAvailable + '*')
            }

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'Install-GPDscManagementTool' {
    Context 'When Install-WindowsFeature is not available' {
        BeforeAll {
            Mock -CommandName Get-Command
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Install-GPDscManagementTool } | Should -Throw -ExpectedMessage ('*' + $script:localizedData.FeatureCmdletNotAvailable + '*')
            }
        }
    }

    Context 'When the feature is installed without restart' {
        BeforeAll {
            Mock -CommandName Get-Command -MockWith { [PSCustomObject] @{ Name = 'Install-WindowsFeature' } }
            Mock -CommandName Install-WindowsFeature -MockWith { [PSCustomObject] @{ Success = $true; RestartNeeded = 'No'; ExitCode = 'Success' } }
            Mock -CommandName Set-DscMachineRebootRequired
        }

        It 'Should install GPMC and return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Install-GPDscManagementTool | Should -BeFalse
            }

            Should -Invoke -CommandName Install-WindowsFeature -Exactly -Times 1 -Scope It -ParameterFilter { $Name -eq 'GPMC' }
            Should -Invoke -CommandName Set-DscMachineRebootRequired -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the feature installation requires a restart' {
        BeforeAll {
            Mock -CommandName Get-Command -MockWith { [PSCustomObject] @{ Name = 'Install-WindowsFeature' } }
            Mock -CommandName Install-WindowsFeature -MockWith { [PSCustomObject] @{ Success = $true; RestartNeeded = 'Yes'; ExitCode = 'SuccessRestartRequired' } }
            Mock -CommandName Set-DscMachineRebootRequired
        }

        It 'Should request a restart and return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Install-GPDscManagementTool -WarningAction 'SilentlyContinue' | Should -BeTrue
            }

            Should -Invoke -CommandName Set-DscMachineRebootRequired -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the feature installation fails' {
        BeforeAll {
            Mock -CommandName Get-Command -MockWith { [PSCustomObject] @{ Name = 'Install-WindowsFeature' } }
            Mock -CommandName Install-WindowsFeature -MockWith { [PSCustomObject] @{ Success = $false; RestartNeeded = 'No'; ExitCode = 'Failed' } }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Install-GPDscManagementTool } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.InstallFeatureFailed -f 'Failed') + '*')
            }
        }
    }
}

Describe 'Assert-GPDscModule' {
    BeforeAll {
        Mock -CommandName Import-GPDscModule
    }

    It 'Should only import the module when it is available' {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $true }
        Mock -CommandName Install-GPDscManagementTool

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Assert-GPDscModule | Should -BeTrue
        }

        Should -Invoke -CommandName Install-GPDscManagementTool -Exactly -Times 0 -Scope It
        Should -Invoke -CommandName Import-GPDscModule -Exactly -Times 1 -Scope It
    }

    It 'Should install and import the module when it is missing' {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $false }
        Mock -CommandName Install-GPDscManagementTool -MockWith { $false }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Assert-GPDscModule | Should -BeTrue
        }

        Should -Invoke -CommandName Install-GPDscManagementTool -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Import-GPDscModule -Exactly -Times 1 -Scope It
    }

    It 'Should return $false when a restart is required' {
        Mock -CommandName Test-GPDscModuleAvailable -MockWith { $false }
        Mock -CommandName Install-GPDscManagementTool -MockWith { $true }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Assert-GPDscModule | Should -BeFalse
        }

        Should -Invoke -CommandName Import-GPDscModule -Exactly -Times 0 -Scope It
    }
}
