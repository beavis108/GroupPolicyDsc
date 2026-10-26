<#
    .SYNOPSIS
        Converts a registry value to a normalized string array that can be
        compared with another value of the same type.

    .DESCRIPTION
        The GroupPolicy cmdlets return DWord and QWord values as signed numbers
        and binary values as byte arrays. The configuration specifies them as
        strings (decimal, hexadecimal, hex bytes). This function converts both
        sides to the same representation:

        - DWord, QWord: the unsigned decimal number.
        - Binary: lowercase hexadecimal string without separators.
        - String, ExpandString: the string.
        - MultiString: the strings.

    .PARAMETER Type
        The registry value type.

    .PARAMETER Value
        The value. Either the value returned by a GroupPolicy cmdlet or the
        result of ConvertTo-GPDscRegistryValue.

    .OUTPUTS
        System.String[]

    .EXAMPLE
        ConvertTo-GPDscComparableRegistryValue -Type 'DWord' -Value -1

        Returns '4294967295'.
#>
function ConvertTo-GPDscComparableRegistryValue
{
    [CmdletBinding()]
    [OutputType([System.String[]], [System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [System.String]
        $Type,

        [Parameter()]
        [AllowNull()]
        [System.Object]
        $Value
    )

    if ($null -eq $Value)
    {
        return , ([System.String[]] @())
    }

    switch ($Type)
    {
        'DWord'
        {
            $number = [System.Int64] $Value

            return , ([System.String[]] @(($number -band 0xFFFFFFFFL).ToString([System.Globalization.CultureInfo]::InvariantCulture)))
        }

        'QWord'
        {
            if ($Value -is [System.UInt64])
            {
                $unsignedNumber = [System.UInt64] $Value
            }
            else
            {
                $unsignedNumber = [System.BitConverter]::ToUInt64([System.BitConverter]::GetBytes([System.Int64] $Value), 0)
            }

            return , ([System.String[]] @($unsignedNumber.ToString([System.Globalization.CultureInfo]::InvariantCulture)))
        }

        'Binary'
        {
            $bytes = [System.Byte[]] @($Value)

            return , ([System.String[]] @((($bytes | ForEach-Object -Process { $_.ToString('x2') }) -join '')))
        }

        'MultiString'
        {
            return , ([System.String[]] @($Value | ForEach-Object -Process { [System.String] $_ }))
        }

        default
        {
            return , ([System.String[]] @([System.String] $Value))
        }
    }
}
