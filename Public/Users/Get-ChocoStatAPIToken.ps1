function Get-ChocoStatAPIToken {
    <#
    .SYNOPSIS
        Lists api tokens in the database depending on the filters
    .DESCRIPTION
        The output can be filtered by one or more UserNames
    .EXAMPLE
        Get-ChocoStatAPIToken

        Lists all api tokens in the database
    .EXAMPLE
        Get-ChocoStatAPIToken -UserName "bob"

        Lists only the api tokens for user with the name "bob"
    .EXAMPLE
        Get-ChocoStatUser -UserName "alice" | Get-ChocoStatAPIToken

        Lists the api token for user "alice"
    .EXAMPLE
        Get-ChocoStatApiToken -APIToken "50371dc1-c5fb-4013-bd53-c1608dbff22e"

        Lists the api token "50371dc1-c5fb-4013-bd53-c1608dbff22e"
    #>

    [CmdletBinding()]
    [OutputType( [PSObject] )]

    param (
        # One or more APITokens to search for
        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]
        $APIToken,

        # One or more UserNames to search for
        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]
        $UserName
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
        $Query = "SELECT * FROM APITokens"
    }

    process {
        $QueryParams = @()

        if ($APIToken) {
            $QueryParams += "(" + ( ($APIToken | ForEach-Object { "APIToken='$_'" } ) -join ' OR ') + ")"
        }

        if ($UserName) {
            $QueryParams += "(" + ( ($UserName | ForEach-Object { "UserName='$_'" } ) -join ' OR ') + ")"
        }
    }

    end {
        if ($QueryParams.Count -gt 0) {
            $Query += " WHERE "
            $Query += $QueryParams -join " AND "
        }
        $Query += ";"

        Write-Verbose "Get-ChocoStatAPIToken: Execute SQL Query: $Query"

        $result = Invoke-SqliteQuery -Query $Query -Database $DbFile

        $result
    }
}
