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
    $script:dscResourceFriendlyName = 'GPOCopy'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'GroupPolicyDsc.IntegrationHelper.psm1') -Force
}

Describe 'DSC_GPOCopy_Integration' -Skip:$script:skipIntegrationTests {
    BeforeAll {
        $script:testEnvironment = Initialize-TestEnvironment `
            -DSCModuleName $script:dscModuleName `
            -DSCResourceName $script:dscResourceName `
            -ResourceType 'Mof' `
            -TestType 'Integration'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        Remove-GPDscTestGpo -Name 'GPDscIT Copy'
        $null = New-GPDscTestGpo -Name 'GPDscIT Copy Source'
        $null = Set-GPRegistryValue -Name 'GPDscIT Copy Source' -Key 'HKLM\Software\Policies\GPDscIT' -ValueName 'Level' -Type 'DWord' -Value 1
    }

    AfterAll {
        Remove-GPDscTestGpo -Name 'GPDscIT Copy', 'GPDscIT Copy Source'

        Restore-TestEnvironment -TestEnvironment $script:testEnvironment
    }

    Context ('When using configuration {0}' -f 'DSC_GPOCopy_Copy_Config') {
        BeforeAll {
            $configurationName = 'DSC_GPOCopy_Copy_Config'
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

        It "Should have set the resource '[GPOCopy]Integration_Test' and all the parameters should match" {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq '[GPOCopy]Integration_Test'
            }

            $resourceCurrentState | Should -Not -BeNullOrEmpty
            $resourceCurrentState.TargetGpoId | Should -Not -BeNullOrEmpty
            $resourceCurrentState.TargetGpoId | Should -Not -Be $resourceCurrentState.SourceGpoId
        }

        It 'Should have copied the settings' {
            (Get-GPRegistryValue -Name 'GPDscIT Copy' -Key 'HKLM\Software\Policies\GPDscIT' -ValueName 'Level').Value | Should -Be 1
        }

        It 'Should return ''True'' when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }
}
