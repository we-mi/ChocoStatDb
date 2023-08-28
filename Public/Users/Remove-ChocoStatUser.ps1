function Remove-ChocoStatUser {
    <#
    .SYNOPSIS
        Removes a user from the database
    .DESCRIPTION
        Removes a user from the database. You can pipe the output from Get-ChocoStatComputer to this cmdlet.
    .NOTES
        This cmdlet does not check if the user exists beforehand.
    .EXAMPLE
        Remove-ChocoStatUser -UserName "bob"

        Removes user with name "bob"
    .EXAMPLE
        Get-ChocoStatUser -UserName "alice" | Remove-ChocoStatUser

        Removes the user with the Name "alice"
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String[]]
        $UserName,

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

        foreach ($singleUser in $UserName) {
            $Query = "DELETE FROM Users WHERE UserName=@singleUser;"
            Write-Verbose "Remove-ChocoStatUser: Execute SQL Query: $Query"

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would remove user with ID '$singleUser'"
            } else {
                $GoAhead = $False
                if ($Confirm) {
                    $answer = Read-Host -Prompt "Remove user with ID '$singleUser' from database? (y/N)"
                    if ($answer -eq "y") { $GoAhead = $True }
                } else { $GoAhead = $True }

                if ($GoAhead) {
                    Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                        singleUser = $singleUser
                    }
                } else {
                    Write-Host -ForegroundColor Magenta "You chose not to remove the user"
                }
            }
        }
    }
}
