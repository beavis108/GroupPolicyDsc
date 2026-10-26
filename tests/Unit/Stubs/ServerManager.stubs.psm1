# Name: ServerManager (hand-written stubs, see README.md)

function Get-WindowsFeature
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String[]]
        $Name
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Install-WindowsFeature
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String[]]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IncludeManagementTools
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}
