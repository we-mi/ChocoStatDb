function Get-ChocoStatComputerPackage {
    <#
    .SYNOPSIS
        Lists packages for one or more computers
    .DESCRIPTION
        Lists packages for one or more computers. You can filter by ComputerID or Computername and PackageName
    .EXAMPLE
        Get-ChocoStatComputerPackage -PackageName "vlc" -ComputerName '%.example.org'

        Lists all computers whose names end with 'example.org' and have "vlc" installed
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

        # One or more PackageNames to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String[]]
        $PackageName,

        # One or more Versions to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String[]]
        $Version
    )

    begin {
        $DbFile = Get-ChocoStatDBFile

        $Query = "SELECT Computers.ComputerName,Computers.ComputerID,Packages.PackageName,Packages.PackageID,Version,Parameters,InstalledOn FROM Computers_Packages,Computers,Packages WHERE Computers_Packages.ComputerID=Computers.ComputerID AND Computers_Packages.PackageID=Packages.PackageID"
    }

    process {

        $QueryFilters = @()

        if ($ComputerID.Count -gt 0) {
            $QueryFilterComputer += $ComputerID | ForEach-Object { "Computers.ComputerID = $_" }
        }

        if ($PackageName) {
            $QueryFilterPackage += $PackageName | ForEach-Object { "Packages.PackageName LIKE '$_'" }
        }

        if ($Version) {
            $QueryFilterVersion += $Version | ForEach-Object { "Computers_Packages.Version LIKE '$_'" }
        }

        if ($QueryFilterComputer.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterComputer -join ' OR '
            $Query += " ) "
        }

        if ($QueryFilterPackage.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterPackage -join ' OR '
            $Query += " ) "
        }

        if ($QueryFilterVersion.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterVersion -join ' OR '
            $Query += " ) "
        }

        $Query += ";"

        Write-Verbose "Get-ChocoStatComputerPackage: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
            ComputerName = $ComputerName
        }
    }

}
