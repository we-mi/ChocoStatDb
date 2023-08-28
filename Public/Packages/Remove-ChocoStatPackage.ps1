function Remove-ChocoStatPackage {
    <#
    .SYNOPSIS
        Removes a package from the database
    .DESCRIPTION
        Removes a package from the database. You will need the PackageID, have a look at 'Get-ChocoStatPackage'. You can pipe the output from Get-ChocoStatPackage to this cmdlet.
    .NOTES
        This cmdlet does not check if the package exists beforehand.
    .EXAMPLE
        Remove-ChocoStatPackage -PackageName "firefox"

        Removes the package with the name "firefox"
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $PackageID,

        [Parameter()]
        [Bool]
        $Confirm = $True,

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        foreach ($singlePackage in $PackageID) {
            $Query = "DELETE FROM Packages WHERE PackageID=@singlePackage; DELETE FROM Computers_Packages WHERE PackageID=@singlePackage; DELETE FROM Computers_FailedPackages WHERE PackageID=@singlePackage;"

            Write-Verbose "Remove-ChocoStatPackage: Execute SQL Query: $Query"

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would remove package with ID '$singlePackage'"
            } else {
                $GoAhead = $False
                if ($Confirm) {
                    $answer = Read-Host -Prompt "Remove package with ID '$singlePackage' from database? (y/N)"
                    if ($answer -eq "y") { $GoAhead = $True }
                } else { $GoAhead = $True }

                if ($GoAhead) {
                    Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                        singlePackage = $singlePackage
                    }
                } else {
                    Write-Host -ForegroundColor Magenta "You chose not to remove the package"
                }
            }
        }
    }
}
