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
    $script:dscResourceFriendlyName = 'GPLink'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'GroupPolicyDsc.IntegrationHelper.psm1') -Force
}

Describe 'DSC_GPLink_Integration' -Skip:$script:skipIntegrationTests {
    BeforeAll {
        $script:testEnvironment = Initialize-TestEnvironment `
            -DSCModuleName $script:dscModuleName `
            -DSCResourceName $script:dscResourceName `
            -ResourceType 'Mof' `
            -TestType 'Integration'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        New-GPDscTestOrganizationalUnit
        $null = New-GPDscTestGpo -Name 'GPDscIT Link'
        $null = New-GPDscTestGpo -Name 'GPDscIT Link 2'
    }

    AfterAll {
        # Remove-GPO also removes the links of the GPOs.
        Remove-GPDscTestGpo -Name 'GPDscIT Link', 'GPDscIT Link 2'
        Remove-GPDscTestOrganizationalUnit

        Restore-TestEnvironment -TestEnvironment $script:testEnvironment
    }

    Context ('When using configuration {0}' -f 'DSC_GPLink_Create_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPLink_Create_Config'
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

        It "Should have set the resource '[GPLink]Integration_Test' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPLink]Integration_Test'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.LinkEnabled | Should -BeTrue
            $resourceCurrentState.Enforced | Should -BeTrue
            $resourceCurrentState.Order | Should -Be 1
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration {0}' -f 'DSC_GPLink_Change_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPLink_Change_Config'
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

        It "Should have set the resource '[GPLink]Integration_Test' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPLink]Integration_Test'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.LinkEnabled | Should -BeFalse
            $resourceCurrentState.Enforced | Should -BeFalse
        }

        It 'Should report the same state as Get-GPInheritance' {
            $link = (Get-GPInheritance -Target $ConfigurationData.AllNodes.OuDN).GpoLinks | Where-Object -FilterScript { $_.DisplayName -eq $ConfigurationData.AllNodes.GpoName }

            $link.Enabled | Should -BeFalse
            $link.Enforced | Should -BeFalse
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration {0}' -f 'DSC_GPLink_Site_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPLink_Site_Config'
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

        It "Should have set the resource '[GPLink]Integration_Test_Site' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPLink]Integration_Test_Site'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Enforced | Should -BeTrue
            $resourceCurrentState.LinkEnabled | Should -BeTrue

            $script:firstSiteLinkOrder = $resourceCurrentState.Order
        }

        It "Should have set the resource '[GPLink]Integration_Test_Site2' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPLink]Integration_Test_Site2'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Enforced | Should -BeFalse

            # Verifies the interpretation of the attribute gPLink: a new link gets the lowest precedence (highest order).
            $resourceCurrentState.Order | Should -BeGreaterThan $script:firstSiteLinkOrder
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration {0}' -f 'DSC_GPLink_Remove_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPLink_Remove_Config'
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

        It "Should have set the resource '[GPLink]Integration_Test' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPLink]Integration_Test'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Absent'
        }

        It "Should have set the resource '[GPLink]Integration_Test_Site' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPLink]Integration_Test_Site'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Absent'
        }

        It "Should have set the resource '[GPLink]Integration_Test_Site2' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPLink]Integration_Test_Site2'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.Ensure | Should -Be 'Absent'
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }
}
