function Remove-ChocoStatComputerSource {
    <#
    .SYNOPSIS
        Removes a Source from a computer from the database
    .DESCRIPTION
        Removes a Source from a computer from the database. You will need the ComputerID, have a look at 'Get-ChocoStatComputer'. You can pipe the output from Get-ChocoStatComputer to this cmdlet.
    .NOTES
        This cmdlet does not check if the Source was linked to the computer beforehand
    .EXAMPLE
        Remove-ChocoStatComputerSource -ComputerID 5 -SourceName "chocolatey"

        Removes source "chocolatey" from computer with ID 5
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName "foo.example.org" | Remove-ChocoStatComputerSource -SourceName "chocolatey"

        Removes source "chocolatey" from computer with name "foo.example.org"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName "%.example.org" | Remove-ChocoStatComputerSource -SourceName "chocolatey"

        Removes source "chocolatey" from all computers which names end with '.example.org'
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # ComputerID to remove the Source from
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $ComputerID,

        # Source to remove from computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $SourceName,

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

        $Query = "DELETE FROM Computers_Sources WHERE SourceName=@SourceName"

        $QueryIDs = [array]($ComputerID | ForEach-Object { " ComputerID=$_" })

        if ($QueryIDs.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryIDs -join ' OR '
            $Query += " )"
        }

        $Query += ";"

        Write-Verbose "Remove-ChocoStatComputerSource: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would remove Source '$SourceName' from computer with IDs '$($ComputerIDs -join ',')'"
        } else {
            $GoAhead = $False
            if ($Confirm) {
                $answer = Read-Host -Prompt "Remove Source '$SourceName' from computer with IDs '$($ComputerID -join ',')' from database? (y/N)"
                if ($answer -eq "y") { $GoAhead = $True }
            } else { $GoAhead = $True }

            if ($GoAhead) {
                Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                    SourceName = $SourceName
                }
            } else {
                Write-Host -ForegroundColor Magenta "You chose not to remove the Source from the computers"
            }
        }
    }
}
