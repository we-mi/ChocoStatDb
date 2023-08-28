function Get-ChocoStatPackage {
    <#
    .SYNOPSIS
        Lists packages in the database depending on the filters
    .DESCRIPTION
        Lists packages in the database including computers where the package is installed or failed to install
    .NOTES
        The output can be filtered by one or more PackageIDs _OR_ one or more PackageNames which might contain SQL-Wildcards
    .EXAMPLE
        Get-ChocoStatPackage

        Lists all packages in the database
    .EXAMPLE
        Get-ChocoStatPackage -PackageName "firefox"

        Lists only the package with the Name "firefox" (This only shows if *any* the database knows this package. You can't really do anything with this information)
    .EXAMPLE
        Get-ChocoStatPackage -PackageName "firefox" -Computers

        Lists only the package with the Name "firefox" and shows which computers have this package installed
    .EXAMPLE
        Get-ChocoStatPackage -PackageName '*fire*'

        Lists all packages which contains "fire"
    #>

    [CmdletBinding(DefaultParameterSetName="PackageName")]
    [OutputType([Object[]])]

    param (
        # One or more ComputerIDs to search for
        [Parameter(
            ParameterSetName = "PackageID",
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $PackageID,

        # One or more ComputerNames to search for (can contain SQL wildcards)
        [Parameter(
            ParameterSetName = "PackageName",
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String[]]
        $PackageName,

        # Should the search include which computers have this package installed?
        [Parameter()]
        [switch]
        $Computers,

        # Should the search include computer where this package failed to install?
        [Parameter()]
        [switch]
        $FailedComputers
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
        $Query = "SELECT * FROM Packages"
    }

    process {

        $QueryFilters = @()
        if ($PackageID) {
            $QueryFilters += $PackageID | ForEach-Object { "PackageID = $_" }
        } elseif ($PackageName) {
            $QueryFilters += $PackageName | ForEach-Object { "PackageName LIKE '$_'" }
        }
    }

    end {
        if ($QueryFilters.Count -gt 0) {
            $Query += " WHERE "
            $Query += $QueryFilters -join ' OR '
        }
        $Query += ";"

        Write-Verbose "Get-ChocoStatPackage: Execute SQL Query: $Query"

        $result = Invoke-SqliteQuery -Query $Query -Database $DbFile | Select-Object PackageID,PackageName

        if ($Computers.IsPresent) {

            $ComputerPackages = Get-ChocoStatComputerPackage -PackageName $result.PackageName

            foreach ($package in $result) {
                $package | Add-Member -MemberType NoteProperty -Name Computers -Value ($ComputerPackages | Where-Object { $_.PackageName -eq $package.PackageName } | Select-Object ComputerName,Version,InstalledOn)
            }
        }

        if ($FailedComputers.IsPresent) {

            $ComputerFailedPackages = Get-ChocoStatComputerFailedPackage -PackageName $result.PackageName

            foreach ($package in $result) {
                $package | Add-Member -MemberType NoteProperty -Name FailedComputers -Value ($ComputerFailedPackages | Where-Object { $_.PackageName -eq $package.PackageName } | Select-Object ComputerName,Version,FailedOn)
            }
        }

        return $result
    }
}
