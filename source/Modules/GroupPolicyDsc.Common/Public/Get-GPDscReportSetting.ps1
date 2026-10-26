<#
    .SYNOPSIS
        Returns a normalized text representation of the settings in a Group
        Policy XML report.

    .DESCRIPTION
        Used to compare the settings of a GPO (Get-GPOReport -ReportType Xml)
        with the settings of a GPO backup (file 'gpreport.xml' of the backup).

        Only the extension data of the sections 'Computer' and 'User' is used.
        Everything that differs between two GPOs with identical settings is
        ignored: the GPO identity, the name, times, version numbers, the
        security descriptor, the links and the namespace prefixes that are
        generated per report (for example 'q1:' in 'xsi:type'). The extensions
        are sorted by their name.

    .PARAMETER ReportXml
        The XML report as string, e.g. the output of
        Get-GPOReport -ReportType Xml.

    .PARAMETER Path
        The path of an XML report file, e.g. the file 'gpreport.xml' of a GPO
        backup. The encoding of the file is detected from its byte order mark.

    .OUTPUTS
        System.String

    .EXAMPLE
        $current = Get-GPDscReportSetting -ReportXml (Get-GPOReport -Name 'Baseline' -ReportType Xml)
        $backup = Get-GPDscReportSetting -Path '.\{backup-id}\gpreport.xml'
        $current -ceq $backup
#>
function Get-GPDscReportSetting
{
    [CmdletBinding(DefaultParameterSetName = 'Xml')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Xml')]
        [System.String]
        $ReportXml,

        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [System.String]
        $Path
    )

    try
    {
        $report = New-Object -TypeName 'System.Xml.XmlDocument'
        $report.PreserveWhitespace = $false

        if ($PSCmdlet.ParameterSetName -eq 'Path')
        {
            $report.Load($Path)
        }
        else
        {
            $report.LoadXml($ReportXml)
        }
    }
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.ReportInvalid -ErrorRecord $_
    }

    $stringBuilder = New-Object -TypeName 'System.Text.StringBuilder'

    foreach ($section in @('Computer', 'User'))
    {
        $null = $stringBuilder.Append('[').Append($section).Append(']')

        $sectionNode = $report.SelectSingleNode(("/*[local-name()='GPO']/*[local-name()='{0}']" -f $section))

        if ($null -eq $sectionNode)
        {
            continue
        }

        $extensions = foreach ($extensionNode in $sectionNode.SelectNodes("*[local-name()='ExtensionData']"))
        {
            $nameNode = $extensionNode.SelectSingleNode("*[local-name()='Name']")
            $extensionName = [System.String]::Empty

            if ($null -ne $nameNode)
            {
                $extensionName = $nameNode.InnerText.Trim()
            }

            [PSCustomObject] @{
                Name  = $extensionName
                Value = ConvertTo-GPDscCanonicalXml -Node $extensionNode
            }
        }

        foreach ($extension in ($extensions | Sort-Object -Property 'Name', 'Value'))
        {
            $null = $stringBuilder.Append($extension.Value)
        }
    }

    return $stringBuilder.ToString()
}
