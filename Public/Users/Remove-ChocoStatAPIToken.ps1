function Remove-ChocoStatAPIToken {
    <#
    .SYNOPSIS
        Removes an APIToken from the database
    .DESCRIPTION
        Removes an APIToken from the database.
    .EXAMPLE
        Get-ChocoStatApiToken -APIToken 3de632c9-11d8-4398-9340-4163e6df5bb8 | Remove-ChocoStatApiToken

        Removes the APIToken 3de632c9-11d8-4398-9340-4163e6df5bb8
    .EXAMPLE
        Get-ChocoStatUser -UserName "alice" | Get-ChocoStatApiToken | Remove-ChocoStatApiToken

        Removes all APITokens of the user "alice"
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String[]]
        $APIToken,

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

        foreach ($singleAPIToken in $APIToken) {
            $Query = "DELETE FROM APITokens WHERE APIToken=@singleAPIToken;"
            Write-Verbose "Remove-ChocoStatAPIToken: Execute SQL Query: $Query"

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would remove APIToken '$singleAPIToken'"
            } else {
                $GoAhead = $False
                if ($Confirm) {
                    $answer = Read-Host -Prompt "Remove APIToken '$singleAPIToken' from database? (y/N)"
                    if ($answer -eq "y") { $GoAhead = $True }
                } else { $GoAhead = $True }

                if ($GoAhead) {
                    Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                        singleAPIToken = $singleAPIToken
                    }
                } else {
                    Write-Host -ForegroundColor Magenta "You chose not to remove the user"
                }
            }
        }
    }
}
