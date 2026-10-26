<#
    .SYNOPSIS
        Converts a boolean value to the values 'Yes' and 'No' used by the
        enumerations EnableLink, EnforceLink and BlockInheritance.

    .PARAMETER Value
        The boolean value.

    .OUTPUTS
        System.String

    .EXAMPLE
        Set-GPLink -Name 'Baseline' -Target $ou -Enforced (ConvertTo-GPDscYesNo -Value $true)
#>
function ConvertTo-GPDscYesNo
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Value
    )

    if ($Value)
    {
        return 'Yes'
    }

    return 'No'
}
