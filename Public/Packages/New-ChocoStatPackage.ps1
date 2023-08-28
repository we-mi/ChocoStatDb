function New-ChocoStatPackage {
    <#
    .SYNOPSIS
        Creates a new package in the database
    .DESCRIPTION
        Creates a new package in the database. Jep, that's all. You don't need a version or anything else to create a new package.
    .EXAMPLE
        New-ChocoStatPackage -PackageName "firefox"

        Creates a new package "firefox"
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # Name of the package
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $PackageName,

        # Return the newly created object
        [Parameter()]
        [Switch]
        $PassThru
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        # Check for existing name
        $double = Get-ChocoStatPackage -PackageName $PackageName
        if ($double.PackageName -eq $PackageName) {
            Throw "PackageName already present"
        }

        $Query = "INSERT INTO Packages (PackageName) VALUES (@PackageName);"
        Write-Verbose "New-ChocoStatPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would create package with name '$PackageName'"
        } else {
            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                PackageName = $PackageName
            }
        }

        if ($PassThru.IsPresent) {
            # to get the ID of the new object
            $package = Get-ChocoStatPackage | Where-Object { $_.PackageName -eq $PackageName }

            $package
        }
    }
}

