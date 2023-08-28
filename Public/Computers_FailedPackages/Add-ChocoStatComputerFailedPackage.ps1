# TODO:
#  Check if package already added -> helpful error message and use Update-ChocoStatComputerPackage
function Add-ChocoStatComputerFailedPackage {
    <#
    .SYNOPSIS
        Adds a failed package to a computer
    .DESCRIPTION
        Adds a failed package with a version and (optional) a failed install date to a computer. You cannot have multiple versions of one failed package linked to one computer. You have to update the dataset to update the version (Update-ChocoStatComputerFailedPackage) or remove the failed package from the computer (Remove-ChocoStatComputerFailedPackage) and add it again
    .EXAMPLE
        Add-ChocoStatComputerFailedPackage -ComputerID 5 -PackageName "vlc" -Version 1.0

        Adds the package "vlc" in version "1.0" to the computer with ID 5
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
        [DateTime]
        $FailedOn = "01.01.1970 00:00:00",

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerObject = Get-ChocoStatComputer -ComputerID $ComputerID -FailedPackages

        if ($null -eq $ComputerObject) {
            Throw "Computer with ID '$ComputerID' does not exist"
        }

        if ($ComputerObject.FailedPackages.PackageName -contains $PackageName) {
            Throw "Failed Package '$PackageName' already attached to computer '$($ComputerObject.ComputerName)'"
        }


        try {
            $PackageObject = New-ChocoStatPackage -PackageName $PackageName -PassThru
        } catch {
            $PackageObject = Get-ChocoStatPackage -PackageName $PackageName
        }

        if ($null -eq $PackageObject) {
            Throw "Could not create or retrieve information about package '$PackageName'"
        }

        $Query = "INSERT INTO Computers_FailedPackages (ComputerID, PackageID, Version, Parameters, FailedOn) VALUES (@ComputerID, @PackageID, @Version, @Parameters, @FailedOn)"
        Write-Verbose "Add-ChocoStatComputerFailedPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would add failed package '$PackageName' to computer '$($ComputerObject.ComputerName)'"
        } else {

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerObject.ComputerID
                PackageID = $PackageObject.PackageID
                Version = $Version
                Parameters = $Parameters
                FailedOn = $FailedOn
            }
        }
    }
}
