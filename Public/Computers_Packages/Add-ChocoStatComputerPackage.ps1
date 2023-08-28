# TODO:
#  Check if package already added -> helpful error message and use Update-ChocoStatComputerPackage
function Add-ChocoStatComputerPackage {
    <#
    .SYNOPSIS
        Adds a package to a computer
    .DESCRIPTION
        Adds a package with a version and (optional) a install date to a computer. You cannot have multiple versions of one package linked to one computer. You have to update the dataset to update the version (Update-ChocoStatComputerPackage) or remove the package from the computer (Remove-ChocoStatComputerPackage) and add it again
    .NOTES
        The parameter "Parameters" has no effect yet as there is currently no way to read the parameters which were used when the package was installed
    .EXAMPLE
        Add-ChocoStatComputerPackage -ComputerName "foo.example.org" -PackageName "vlc" -Version 1.0

        Adds the package "vlc" in version "1.0" to the computer "foo.example.org"
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # ComputerID for adding the packages
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int]
        $ComputerID,

        # A PackageName which should be added to the computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $PackageName,

        # The version of the package
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $Version,

        # The parameters with which the package was installed
        [Parameter()]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $Parameters,

        # The date the package was installed or updated to
        [Parameter()]
        [datetime]
        $InstalledOn = "01.01.1970 00:00:00",

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerObject = Get-ChocoStatComputer -ComputerID $ComputerID -Packages

        if ($null -eq $ComputerObject) {
            Throw "Computer with ID '$ComputerID' does not exist"
        }

        if ($ComputerObject.Packages.PackageName -contains $PackageName) {
            Throw "Package '$PackageName' already attached to computer '$($ComputerObject.ComputerName)'"
        }

        try {
            $PackageObject = New-ChocoStatPackage -PackageName $PackageName -PassThru
        } catch {
            $PackageObject = Get-ChocoStatPackage -PackageName $PackageName
        }

        if ($null -eq $PackageObject) {
            Throw "Could not create or retrieve information about package '$PackageName'"
        }

        $Query = "INSERT INTO Computers_Packages (ComputerID, PackageID, Version, Parameters, InstalledOn) VALUES (@ComputerID, @PackageID, @Version, @Parameters, @InstalledOn)"
        Write-Verbose "Add-ChocoStatComputerPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would add package '$PackageName' to computer '$($ComputerObject.ComputerName)'"
        } else {

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerObject.ComputerID
                PackageID = $PackageObject.PackageID
                Version = $Version
                Parameters = $Parameters
                InstalledOn = $InstalledOn
            }
        }
    }
}
