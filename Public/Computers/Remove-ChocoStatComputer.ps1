function Remove-ChocoStatComputer {
    <#
    .SYNOPSIS
        Removes a computer from the database
    .DESCRIPTION
        Removes a computer from the database. You will need the ComputerID, have a look at 'Get-ChocoStatComputer'. You can pipe the output from Get-ChocoStatComputer to this cmdlet.
    .NOTES
        This cmdlet does not check if the computer exists beforehand.
    .EXAMPLE
        Remove-ChocoStatComputer -ComputerID 5

        Removes the computer with the ID 5
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $ComputerID,

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

        foreach ($singleComputer in $ComputerID) {
            $Query = "DELETE FROM Computers WHERE ComputerID=@singleComputer; DELETE FROM Computers_Packages WHERE ComputerID=@singleComputer; DELETE FROM Computers_FailedPackages WHERE ComputerID=@singleComputer; DELETE FROM Computers_Sources WHERE ComputerID=@singleComputer; DELETE FROM ComputerPasswords WHERE ComputerID=@singleComputer"

            Write-Verbose "Remove-ChocoStatComputer: Execute SQL Query: $Query"

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would remove computer with ID '$singleComputer'"
            } else {
                $GoAhead = $False
                if ($Confirm) {
                    $answer = Read-Host -Prompt "Remove computer with ID '$singleComputer' from database? (y/N)"
                    if ($answer -eq "y") { $GoAhead = $True }
                } else { $GoAhead = $True }

                if ($GoAhead) {
                    Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                        singleComputer = $singleComputer
                    }
                } else {
                    Write-Host -ForegroundColor Magenta "You chose not to remove the computer"
                }
            }
        }
    }
}
