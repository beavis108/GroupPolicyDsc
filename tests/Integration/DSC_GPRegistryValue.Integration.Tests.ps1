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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'GroupPolicyDsc.IntegrationHelper.psm1') -Force

    # Only runs on a domain controller of a lab domain with $env:GPDSC_INTEGRATION_TEST = '1'.
    $script:skipIntegrationTests = -not (Test-GPDscIntegrationEnvironment)
}

BeforeAll {
    $script:dscModuleName = 'GroupPolicyDsc'
    $script:dscResourceFriendlyName = 'GPRegistryValue'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'GroupPolicyDsc.IntegrationHelper.psm1') -Force
}

Describe 'DSC_GPRegistryValue_Integration' -Skip:$script:skipIntegrationTests {
    BeforeAll {
        $script:testEnvironment = Initialize-TestEnvironment `
            -DSCModuleName $script:dscModuleName `
            -DSCResourceName $script:dscResourceName `
            -ResourceType 'Mof' `
            -TestType 'Integration'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        $null = New-GPDscTestGpo -Name 'GPDscIT Registry'
    }

    AfterAll {
        Remove-GPDscTestGpo -Name 'GPDscIT Registry'

        Restore-TestEnvironment -TestEnvironment $script:testEnvironment
    }

    Context ('When using configuration {0}' -f 'DSC_GPRegistryValue_Set_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPRegistryValue_Set_Config'
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction 'Stop'
            } | Should -Not -Throw
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_DWord' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_DWord'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Type | Should -Be 'DWord'
            $resourceCurrentState.Value | Should -Be '4294967295'
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_QWord' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_QWord'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Type | Should -Be 'QWord'
            $resourceCurrentState.Value | Should -Be '4294967296'
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_String' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_String'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Value | Should -Be 'Contoso'
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_ExpandString' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_ExpandString'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Type | Should -Be 'ExpandString'
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_MultiString' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_MultiString'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Value | Should -Be @('a', 'b', 'c')
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_Binary' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_Binary'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Value | Should -Be '01ff0a'
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_Default' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_Default'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            # Verifies the handling of the default value of a key.
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Value | Should -Be 'DefaultValue'
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_User' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_User'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration {0}' -f 'DSC_GPRegistryValue_DeleteAndRemove_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPRegistryValue_DeleteAndRemove_Config'
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction 'Stop'
            } | Should -Not -Throw
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_DWord' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_DWord'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.PolicyState | Should -Be 'Delete'
        }

        It "Should have set the resource '[GPRegistryValue]Integration_Test_String' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPRegistryValue]Integration_Test_String'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Absent'
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }
}
