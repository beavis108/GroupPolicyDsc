<#
    .SYNOPSIS
        Returns a GUID from an element of 'bkupInfo.xml' in lowercase without
        braces, or $null.
#>
function Get-GPDscXmlGuid
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlNode]
        $Xml,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ElementName
    )

    $text = Get-GPDscXmlText -Xml $Xml -XPath ("/*/*[local-name()='{0}']" -f $ElementName)

    if ([System.String]::IsNullOrEmpty($text))
    {
        return $null
    }

    return ($text -replace '[{}]', '').ToLowerInvariant()
}
