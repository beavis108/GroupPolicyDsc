<#
    .SYNOPSIS
        Converts the value of a DSC configuration (a string array) to the value
        expected by Set-GPRegistryValue and Set-GPPrefRegistryValue.

    .DESCRIPTION
        The DSC schemas declare the registry value as a string array, so that one
        property can carry every registry value type:

        - String, ExpandString: exactly one string.
        - DWord, QWord: one number, decimal or hexadecimal ('0x' prefix). Values
          above Int32/Int64.MaxValue are converted to the signed value with the
          same bit pattern, because the registry API stores signed values.
        - Binary: one hexadecimal string, bytes may be separated by spaces,
          commas or hyphens ('01 ff', '01,ff', '01FF' or '0x01FF').
        - MultiString: one or more strings.

    .PARAMETER Type
        The registry value type.

    .PARAMETER Value
        The value as specified in the configuration.

    .OUTPUTS
        System.Object

    .EXAMPLE
        ConvertTo-GPDscRegistryValue -Type 'DWord' -Value '0xffffffff'

        Returns -1.
#>
function ConvertTo-GPDscRegistryValue
{
    [CmdletBinding()]
    [OutputType([System.String], [System.Int32], [System.Int64], [System.Byte[]], [System.String[]], [System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [System.String]
        $Type,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Value
    )

    if ($null -eq $Value -or $Value.Count -eq 0)
    {
        if ($Type -in @('String', 'ExpandString', 'MultiString'))
        {
            if ($Type -eq 'MultiString')
            {
                return , ([System.String[]] @())
            }

            return [System.String]::Empty
        }

        New-ArgumentException -ArgumentName 'Value' -Message ($script:localizedData.MissingRegistryValue -f $Type)
    }

    if ($Type -eq 'MultiString')
    {
        return , ([System.String[]] $Value)
    }

    if ($Value.Count -gt 1)
    {
        New-ArgumentException -ArgumentName 'Value' -Message ($script:localizedData.InvalidRegistryValue -f ($Value -join ', '), $Type)
    }

    $singleValue = [System.String] $Value[0]

    switch ($Type)
    {
        { $_ -in @('String', 'ExpandString') }
        {
            return $singleValue
        }

        'DWord'
        {
            $number = ConvertTo-GPDscUnsignedNumber -Value $singleValue -Type $Type -Maximum ([System.UInt32]::MaxValue)

            return [System.BitConverter]::ToInt32([System.BitConverter]::GetBytes([System.UInt32] $number), 0)
        }

        'QWord'
        {
            $number = ConvertTo-GPDscUnsignedNumber -Value $singleValue -Type $Type -Maximum ([System.UInt64]::MaxValue)

            return [System.BitConverter]::ToInt64([System.BitConverter]::GetBytes([System.UInt64] $number), 0)
        }

        'Binary'
        {
            $hexString = $singleValue.Trim() -replace '^0x', '' -replace '[\s,\-]', ''

            if ($hexString.Length % 2 -ne 0 -or $hexString -notmatch '^[0-9a-fA-F]*$')
            {
                New-ArgumentException -ArgumentName 'Value' -Message ($script:localizedData.InvalidRegistryValue -f $singleValue, $Type)
            }

            $bytes = New-Object -TypeName 'System.Byte[]' -ArgumentList ($hexString.Length / 2)

            for ($index = 0; $index -lt $bytes.Length; $index++)
            {
                $bytes[$index] = [System.Convert]::ToByte($hexString.Substring($index * 2, 2), 16)
            }

            return , $bytes
        }
    }
}
