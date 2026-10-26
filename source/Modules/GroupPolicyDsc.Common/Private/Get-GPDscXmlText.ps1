<#
    .SYNOPSIS
        Returns the trimmed inner text of the first node matching an XPath
        expression, or $null.
#>
function Get-GPDscXmlText
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
        $XPath
    )

    $node = $Xml.SelectSingleNode($XPath)

    if ($null -eq $node)
    {
        return $null
    }

    return $node.InnerText.Trim()
}
