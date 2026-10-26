<#
    .SYNOPSIS
        Serializes an XML node to a canonical string that does not depend on
        namespace prefixes, attribute order or whitespace.

    .PARAMETER Node
        The XML node.
#>
function ConvertTo-GPDscCanonicalXml
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlNode]
        $Node
    )

    switch ($Node.NodeType)
    {
        'Element'
        {
            $attributes = foreach ($attribute in $Node.Attributes)
            {
                if ($attribute.Prefix -eq 'xmlns' -or $attribute.LocalName -eq 'xmlns')
                {
                    continue
                }

                $attributeValue = $attribute.Value

                # Resolve 'prefix:Type' in xsi:type to '{namespace}Type'.
                if ($attribute.LocalName -eq 'type' -and $attribute.NamespaceURI -eq 'http://www.w3.org/2001/XMLSchema-instance' -and $attributeValue -match '^(?<prefix>[^:]+):(?<type>.+)$')
                {
                    $attributeValue = '{{{0}}}{1}' -f $Node.GetNamespaceOfPrefix($Matches['prefix']), $Matches['type']
                }

                '{{{0}}}{1}="{2}"' -f $attribute.NamespaceURI, $attribute.LocalName, $attributeValue
            }

            $children = foreach ($childNode in $Node.ChildNodes)
            {
                ConvertTo-GPDscCanonicalXml -Node $childNode
            }

            return '<{{{0}}}{1} {2}>{3}</>' -f $Node.NamespaceURI, $Node.LocalName, ((@($attributes) | Sort-Object) -join ' '), ($children -join '')
        }

        { $_ -in @('Text', 'CDATA', 'SignificantWhitespace') }
        {
            return $Node.Value.Trim()
        }

        default
        {
            # Comments, whitespace and processing instructions are ignored.
            return [System.String]::Empty
        }
    }
}
