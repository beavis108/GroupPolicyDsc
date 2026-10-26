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

Describe 'Get-GPDscConnectionParameter' {
    It 'Should only return the specified values' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-GPDscConnectionParameter -Domain 'contoso.com' -Server ''

            $result.Keys | Should -HaveCount 1
            $result.Domain | Should -Be 'contoso.com'

            (Get-GPDscConnectionParameter).Keys | Should -HaveCount 0
        }
    }

    It 'Should use the parameter name DomainName when requested' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-GPDscConnectionParameter -Domain 'contoso.com' -Server 'dc01' -DomainParameterName 'DomainName'

            $result.DomainName | Should -Be 'contoso.com'
            $result.Server | Should -Be 'dc01'
            $result.ContainsKey('Domain') | Should -BeFalse
        }
    }
}

Describe 'ConvertTo-GPDscYesNo' {
    It 'Should return <Expected> for <Value>' -ForEach @(
        @{ Value = $true; Expected = 'Yes' }
        @{ Value = $false; Expected = 'No' }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-GPDscYesNo -Value $Value | Should -BeExactly $Expected
        }
    }
}

Describe 'Test-GPDscSiteTarget' {
    It 'Should return <Expected> for <Target>' -ForEach @(
        @{ Target = 'CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=contoso,DC=com'; Expected = $true }
        @{ Target = 'cn=Berlin,cn=sites,cn=configuration,dc=contoso,dc=com'; Expected = $true }
        @{ Target = 'OU=Servers,DC=contoso,DC=com'; Expected = $false }
        @{ Target = 'DC=contoso,DC=com'; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-GPDscSiteTarget -Target $Target | Should -Be $Expected
        }
    }
}

Describe 'ConvertFrom-GPDscGpLink' {
    It 'Should return no links for an empty value' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertFrom-GPDscGpLink -GpLink '' | Should -HaveCount 0
            ConvertFrom-GPDscGpLink -GpLink ' ' | Should -HaveCount 0
        }
    }

    It 'Should parse the options and calculate the link order' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $gpLink = '[LDAP://cn={11111111-1111-1111-1111-111111111111},cn=policies,cn=system,DC=contoso,DC=com;0]' +
                '[LDAP://cn={22222222-2222-2222-2222-222222222222},cn=policies,cn=system,DC=contoso,DC=com;1]' +
                '[LDAP://CN={33333333-3333-3333-3333-333333333333},CN=Policies,CN=System,DC=contoso,DC=com;2]' +
                '[LDAP://cn={44444444-4444-4444-4444-444444444444},cn=policies,cn=system,DC=contoso,DC=com;3]'

            $result = ConvertFrom-GPDscGpLink -GpLink $gpLink

            $result | Should -HaveCount 4

            $result[0].GpoId | Should -Be ([System.Guid] '11111111-1111-1111-1111-111111111111')
            $result[0].Enabled | Should -BeTrue
            $result[0].Enforced | Should -BeFalse
            $result[0].Order | Should -Be 4

            $result[1].Enabled | Should -BeFalse
            $result[1].Enforced | Should -BeFalse

            $result[2].Enabled | Should -BeTrue
            $result[2].Enforced | Should -BeTrue

            $result[3].Enabled | Should -BeFalse
            $result[3].Enforced | Should -BeTrue
            $result[3].Order | Should -Be 1
        }
    }
}

Describe 'ConvertTo-GPDscRegistryValue' {
    It 'Should convert <Type> <Value> to <Expected>' -ForEach @(
        @{ Type = 'String'; Value = @('Contoso'); Expected = 'Contoso' }
        @{ Type = 'ExpandString'; Value = @('%SystemRoot%\Temp'); Expected = '%SystemRoot%\Temp' }
        @{ Type = 'DWord'; Value = @('1'); Expected = 1 }
        @{ Type = 'DWord'; Value = @('0x10'); Expected = 16 }
        @{ Type = 'DWord'; Value = @('4294967295'); Expected = -1 }
        @{ Type = 'DWord'; Value = @('0xFFFFFFFF'); Expected = -1 }
        @{ Type = 'QWord'; Value = @('18446744073709551615'); Expected = [System.Int64] -1 }
        @{ Type = 'QWord'; Value = @('0x100000000'); Expected = [System.Int64] 4294967296 }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-GPDscRegistryValue -Type $Type -Value $Value | Should -Be $Expected
        }
    }

    It 'Should convert a binary value written as <Value>' -ForEach @(
        @{ Value = '01 ff 0A' }
        @{ Value = '01,FF,0a' }
        @{ Value = '01ff0a' }
        @{ Value = '0x01FF0A' }
        @{ Value = '01-ff-0a' }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-GPDscRegistryValue -Type 'Binary' -Value $Value

            , $result | Should -BeOfType [System.Byte[]]
            $result | Should -Be @([System.Byte] 1, [System.Byte] 255, [System.Byte] 10)
        }
    }

    It 'Should return a string array for MultiString' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-GPDscRegistryValue -Type 'MultiString' -Value @('a', 'b')

            , $result | Should -BeOfType [System.String[]]
            $result | Should -Be @('a', 'b')
        }
    }

    It 'Should return an empty string for a String without value' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-GPDscRegistryValue -Type 'String' -Value @() | Should -BeExactly ''
        }
    }

    It 'Should throw for the invalid value <Value> of type <Type>' -ForEach @(
        @{ Type = 'DWord'; Value = @('abc') }
        @{ Type = 'DWord'; Value = @('4294967296') }
        @{ Type = 'DWord'; Value = @('-1') }
        @{ Type = 'Binary'; Value = @('0g') }
        @{ Type = 'Binary'; Value = @('123') }
        @{ Type = 'String'; Value = @('a', 'b') }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            { ConvertTo-GPDscRegistryValue -Type $Type -Value $Value } | Should -Throw -ExpectedMessage '*can not be converted*'
        }
    }

    It 'Should throw when a DWord has no value' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { ConvertTo-GPDscRegistryValue -Type 'DWord' -Value @() } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.MissingRegistryValue -f 'DWord') + '*')
        }
    }
}

Describe 'ConvertTo-GPDscComparableRegistryValue' {
    It 'Should normalize <Type> <Value> to <Expected>' -ForEach @(
        @{ Type = 'DWord'; Value = -1; Expected = @('4294967295') }
        @{ Type = 'DWord'; Value = 16; Expected = @('16') }
        @{ Type = 'DWord'; Value = [System.UInt32] 4294967295; Expected = @('4294967295') }
        @{ Type = 'QWord'; Value = [System.Int64] -1; Expected = @('18446744073709551615') }
        @{ Type = 'String'; Value = 'Contoso'; Expected = @('Contoso') }
        @{ Type = 'MultiString'; Value = @('a', 'b'); Expected = @('a', 'b') }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-GPDscComparableRegistryValue -Type $Type -Value $Value

            $result | Should -Be $Expected
        }
    }

    It 'Should normalize a byte array to a lowercase hexadecimal string' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-GPDscComparableRegistryValue -Type 'Binary' -Value ([System.Byte[]] @(1, 255, 10))

            $result | Should -Be @('01ff0a')
        }
    }

    It 'Should return an empty array for $null' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-GPDscComparableRegistryValue -Type 'String' -Value $null

            $result | Should -HaveCount 0
        }
    }

    It 'Should make the desired and the current value comparable' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $desired = ConvertTo-GPDscComparableRegistryValue -Type 'DWord' -Value (ConvertTo-GPDscRegistryValue -Type 'DWord' -Value '0xFFFFFFFF')
            $current = ConvertTo-GPDscComparableRegistryValue -Type 'DWord' -Value -1

            $desired | Should -Be $current
        }
    }
}
