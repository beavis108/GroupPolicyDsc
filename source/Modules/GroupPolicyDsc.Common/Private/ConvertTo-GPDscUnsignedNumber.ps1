<#
    .SYNOPSIS
        Parses a decimal or hexadecimal number.

    .PARAMETER Value
        The number as string. Hexadecimal numbers must have the prefix '0x'.

    .PARAMETER Type
        The registry value type, used in the error message.

    .PARAMETER Maximum
        The largest allowed value.
#>
function ConvertTo-GPDscUnsignedNumber
{
    [CmdletBinding()]
    [OutputType([System.UInt64])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Value,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $Maximum
    )

    $trimmedValue = $Value.Trim()
    $number = [System.UInt64] 0

    if ($trimmedValue -match '^0x(?<hex>[0-9a-fA-F]+)$')
    {
        $isNumber = [System.UInt64]::TryParse(
            $Matches['hex'],
            [System.Globalization.NumberStyles]::AllowHexSpecifier,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref] $number
        )
    }
    else
    {
        $isNumber = [System.UInt64]::TryParse(
            $trimmedValue,
            [System.Globalization.NumberStyles]::None,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref] $number
        )
    }

    if (-not $isNumber -or $number -gt $Maximum)
    {
        New-ArgumentException -ArgumentName 'Value' -Message ($script:localizedData.InvalidRegistryValue -f $Value, $Type)
    }

    return $number
}
