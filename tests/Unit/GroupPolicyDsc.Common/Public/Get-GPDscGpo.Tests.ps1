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

Describe 'Get-GPDscGpo' {
    It 'Should return the GPO and pass the connection parameters' {
        Mock -CommandName Get-GPO -MockWith { [PSCustomObject] @{ DisplayName = 'Baseline'; Id = [System.Guid]::NewGuid() } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-GPDscGpo -Name 'Baseline' -Domain 'contoso.com' -Server 'dc01').DisplayName | Should -Be 'Baseline'
        }

        Should -Invoke -CommandName Get-GPO -Exactly -Times 1 -Scope It -ParameterFilter {
            $Name -eq 'Baseline' -and $Domain -eq 'contoso.com' -and $Server -eq 'dc01'
        }
    }

    It 'Should return $null when the GPO does not exist' {
        Mock -CommandName Get-GPO -MockWith {
            $exception = [System.ArgumentException]::new('A GPO with the display name "Baseline" was not found.')
            throw [System.Management.Automation.ErrorRecord]::new($exception, 'GpoWithNameNotFound,Microsoft.GroupPolicy.Commands.GetGpoCommand', 'ObjectNotFound', $null)
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-GPDscGpo -Name 'Baseline' | Should -BeNullOrEmpty
        }
    }

    It 'Should throw when the domain can not be contacted' {
        Mock -CommandName Get-GPO -MockWith {
            $exception = [System.Runtime.InteropServices.COMException]::new('The server is not operational.')
            throw [System.Management.Automation.ErrorRecord]::new($exception, 'System.Runtime.InteropServices.COMException,Microsoft.GroupPolicy.Commands.GetGpoCommand', 'NotSpecified', $null)
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Get-GPDscGpo -Name 'Baseline' } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.GpoQueryFailed -f 'Baseline') + '*')
        }
    }
}

Describe 'Get-GPDscStarterGpo' {
    It 'Should return the Starter GPO' {
        Mock -CommandName Get-GPStarterGPO -MockWith { [PSCustomObject] @{ DisplayName = 'Template'; Id = [System.Guid]::NewGuid() } }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-GPDscStarterGpo -Name 'Template').DisplayName | Should -Be 'Template'
        }
    }

    It 'Should return $null when the Starter GPO does not exist' {
        Mock -CommandName Get-GPStarterGPO -MockWith {
            $exception = [System.ArgumentException]::new('not found')
            throw [System.Management.Automation.ErrorRecord]::new($exception, 'StarterGpoWithNameNotFound', 'ObjectNotFound', $null)
        }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-GPDscStarterGpo -Name 'Template' | Should -BeNullOrEmpty
        }
    }

    It 'Should throw on other errors' {
        Mock -CommandName Get-GPStarterGPO -MockWith { throw 'Access is denied.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Get-GPDscStarterGpo -Name 'Template' } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.StarterGpoQueryFailed -f 'Template') + '*')
        }
    }
}

Describe 'Get-GPDscWmiFilter' {
    It 'Should throw the correct error when the GPMC API is not available' {
        Mock -CommandName New-Object -MockWith { throw 'Cannot find type [Microsoft.GroupPolicy.GPDomain].' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Get-GPDscWmiFilter -Name 'Server' -Domain 'contoso.com' } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.WmiFilterQueryFailed -f 'contoso.com') + '*')
        }
    }

    It 'Should return the WMI filter with the given name' {
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq 'Microsoft.GroupPolicy.GPDomain' } -MockWith {
            $gpDomain = [PSCustomObject] @{ Name = 'contoso.com' }
            $gpDomain | Add-Member -MemberType ScriptMethod -Name 'SearchWmiFilters' -Value {
                param ($criteria)
                [PSCustomObject] @{ Name = 'Clients' }
                [PSCustomObject] @{ Name = 'Servers' }
            }
            $gpDomain
        }
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq 'Microsoft.GroupPolicy.GPSearchCriteria' } -MockWith { [PSCustomObject] @{} }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-GPDscWmiFilter -Name 'Servers' -Domain 'contoso.com' -Server 'dc01').Name | Should -Be 'Servers'
            Get-GPDscWmiFilter -Name 'Unknown' | Should -BeNullOrEmpty
        }

        Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It -ParameterFilter {
            $TypeName -eq 'Microsoft.GroupPolicy.GPDomain' -and $ArgumentList -and $ArgumentList[0] -eq 'contoso.com' -and $ArgumentList[1] -eq 'dc01'
        }
    }
}
