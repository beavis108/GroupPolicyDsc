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
    $script:dscResourceFriendlyName = 'GPO'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'GroupPolicyDsc.IntegrationHelper.psm1') -Force
}

Describe 'DSC_GPO_Integration' -Skip:$script:skipIntegrationTests {
    BeforeAll {
        $script:testEnvironment = Initialize-TestEnvironment `
            -DSCModuleName $script:dscModuleName `
            -DSCResourceName $script:dscResourceName `
            -ResourceType 'Mof' `
            -TestType 'Integration'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile
    }

    AfterAll {
        Remove-GPDscTestGpo -Name 'GPDscIT GPO', 'GPDscIT GPO Renamed'

        Restore-TestEnvironment -TestEnvironment $script:testEnvironment
    }

    Context ('When using configuration {0}' -f 'DSC_GPO_Create_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPO_Create_Config'
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

        It "Should have set the resource '[GPO]Integration_Test' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPO]Integration_Test'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Comment | Should -Be $ConfigurationData.AllNodes.Comment
            $resourceCurrentState.Status | Should -Be 'UserSettingsDisabled'
            $resourceCurrentState.Id | Should -Not -BeNullOrEmpty

            $script:gpoId = $resourceCurrentState.Id
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration {0}' -f 'DSC_GPO_Rename_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPO_Rename_Config'
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

        It "Should have set the resource '[GPO]Integration_Test' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPO]Integration_Test'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.RenamedGpoName
            $resourceCurrentState.Id | Should -Be $script:gpoId -Because 'the GPO must be renamed, not recreated'
        }

        It 'Should not find the GPO with the previous name' {
            Get-GPO -All | Where-Object -FilterScript { $_.DisplayName -eq $ConfigurationData.AllNodes.GpoName } | Should -BeNullOrEmpty
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration {0}' -f 'DSC_GPO_Remove_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPO_Remove_Config'
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

        It "Should have set the resource '[GPO]Integration_Test' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPO]Integration_Test'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            # Verifies that a missing GPO is detected as absent (error classification of Get-GPO).
            $resourceCurrentState.Ensure | Should -Be 'Absent'
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }
}
