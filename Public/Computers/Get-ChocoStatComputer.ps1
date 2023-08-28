function Get-ChocoStatComputer {
    <#
    .SYNOPSIS
        Lists computers in the database depending on the filters
    .DESCRIPTION
        Lists computers in the database including packages and sources
    .NOTES
        The output can be filtered by one or more ComputerIDs _OR_ one or more ComputerNames which might contain SQL-Wildcards
    .EXAMPLE
        Get-ChocoStatComputer

        Lists all computers in the database
    .EXAMPLE
        Get-ChocoStatComputer -ComputerID 5

        Lists only the computer with the ID "5"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerID 5,7

        Lists only the computers with the ID "5" and "7"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName '%.example.org'

        Lists all computers which ends with .example.org
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName '%.example.org','%foo%'

        Lists all computers which ends with ".example.org" or which contains the word foo
    #>

    [CmdletBinding(DefaultParameterSetName="ComputerName")]
    [OutputType([Object[]])]

    param (
        # One or more ComputerIDs to search for
        [Parameter(
            ParameterSetName = "ComputerID",
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $ComputerID,

        # One or more ComputerNames to search for (can contain SQL wildcards)
        [Parameter(
            ParameterSetName = "ComputerName",
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String[]]
        $ComputerName,

        # Should the search include package information for computers?
        [Parameter()]
        [switch]
        $Packages,

        # Should the search include failed package information for computers?
        [Parameter()]
        [switch]
        $FailedPackages,

        # Should the search include source information for computers?
        [Parameter()]
        [switch]
        $Sources
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
        $Query = "SELECT * FROM Computers"
    }

    process {

        $QueryFilters = @()
        if ($ComputerID) {
            $QueryFilters += $ComputerID | ForEach-Object { "ComputerID = $_" }
        } elseif ($ComputerName) {
            $QueryFilters += $ComputerName | ForEach-Object { "ComputerName LIKE '$_'" }
        }
    }

    end {
        if ($QueryFilters.Count -gt 0) {
            $Query += " WHERE "
            $Query += $QueryFilters -join ' OR '
        }
        $Query += ";"

        Write-Verbose "Get-ChocoStatComputer: Execute SQL Query: $Query"

        $result = Invoke-SqliteQuery -Query $Query -Database $DbFile | Select-Object ComputerID,ComputerName,@{N='LastContact';E={ $_.LastContact.ToString() }}

        if ($Packages.IsPresent) {
            foreach ($computer in $result) {
                $computer | Add-Member -MemberType NoteProperty -Name Packages -Value (Get-ChocoStatComputerPackage -ComputerID $computer.ComputerID | Select-Object PackageName,Version,InstalledOn)
            }
        }

        if ($FailedPackages.IsPresent) {
            foreach ($computer in $result) {
                $computer | Add-Member -MemberType NoteProperty -Name FailedPackages -Value (Get-ChocoStatComputerFailedPackage -ComputerID $computer.ComputerID | Select-Object PackageName,Version,FailedOn)
            }
        }

        if ($Sources.IsPresent) {
            foreach ($computer in $result) {
                $computer | Add-Member -MemberType NoteProperty -Name Sources -Value (Get-ChocoStatComputerSource -ComputerID $computer.ComputerID | Select-Object SourceName,SourceURL,Enabled,Priority,ByPassProxy,SelfService,AdminOnly)
            }
        }

        return $result
    }
}
