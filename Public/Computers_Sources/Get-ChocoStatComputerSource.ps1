function Get-ChocoStatComputerSource {
    <#
    .SYNOPSIS
        Lists Sources for one or more computers
    .DESCRIPTION
        Lists Sources for one or more computers. You can filter by ComputerID, SourceName and/or SourceURL
    .EXAMPLE
        Get-ChocoStatComputerSource -SourceName "chocolatey" -ComputerName '%.example.org'

        Lists all computers whose names end with 'example.org' and have the source named "chocolatey" configured
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # One or more ComputerIDs to search for
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int[]]
        $ComputerID,

        # One or more SourceNames to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String[]]
        $SourceName,

        # One or more SourceNames to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String[]]
        $SourceURL
    )

    begin {
        $DbFile = Get-ChocoStatDBFile

        $Query = "SELECT Computers.ComputerName,Computers.ComputerID,SourceName,SourceUrl,Enabled,Priority,ByPassProxy,SelfService,AdminOnly FROM Computers_Sources,Computers WHERE Computers_Sources.ComputerID=Computers.ComputerID"
    }

    process {

        if ($ComputerID.Count -gt 0) {
            $QueryFilterComputer += $ComputerID | ForEach-Object { "Computers.ComputerID = $_" }
        }

        if ($SourceName) {
            $QueryFilterSourceName += $SourceName | ForEach-Object { "Computers_Sources.SourceName LIKE '$_'" }
        }

        if ($SourceURL) {
            $QueryFilterSourceURL += $SourceURL | ForEach-Object { "Computers_Sources.SourceURL LIKE '$_'" }
        }

        if ($QueryFilterComputer.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterComputer -join ' OR '
            $Query += " ) "
        }

        if ($QueryFilterSourceName.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterSourceName -join ' OR '
            $Query += " ) "
        }

        if ($QueryFilterSourceURL.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterSourceURL -join ' OR '
            $Query += " ) "
        }

        $Query += ";"

        Write-Verbose "Get-ChocoStatComputerSource: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $DbFile
    }
}
