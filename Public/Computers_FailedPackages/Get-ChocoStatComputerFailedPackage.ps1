function Get-ChocoStatComputerFailedPackage {
    <#
    .SYNOPSIS
        Lists failed packages for one or more computers
    .DESCRIPTION
        Lists failed packages for one or more computers. You can filter by ComputerID and PackageName
    .EXAMPLE
        Get-ChocoStatComputerFailedPackage -PackageName "vlc" -ComputerName '%.example.org'

        Lists all computers whose names end with 'example.org' and where "vlc" were tried to install but failed
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

        $Query = "SELECT Computers.ComputerName,Computers.ComputerID,Packages.PackageName,Packages.PackageID,Version,Parameters,FailedOn FROM Computers_FailedPackages,Computers,Packages WHERE Computers_FailedPackages.ComputerID=Computers.ComputerID AND Computers_FailedPackages.PackageID=Packages.PackageID"
    }

    process {

        if ($ComputerID.Count -gt 0) {
            $QueryFilterComputer += $ComputerID | ForEach-Object { "Computers.ComputerID = $_" }
        }

        if ($PackageName) {
            $QueryFilterPackage += $PackageName | ForEach-Object { "Packages.PackageName LIKE '$_'" }
        }

        if ($Version) {
            $QueryFilterVersion += $Version | ForEach-Object { "Computers_FailedPackages.Version LIKE '$_'" }
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

        Write-Verbose "Get-ChocoStatComputerFailedPackage: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $DbFile
    }

}
