function Get-ChocoStatUser {
    <#
    .SYNOPSIS
        Lists users in the database depending on the filters
    .DESCRIPTION
        The output can be filtered by providing a username which might contain SQL-Wildcards
    .EXAMPLE
        Get-ChocoStatUser

        Lists all users in the database
    .EXAMPLE
        Get-ChocoStatComputer -UserName "bob"

        Lists only the user with the name "bob"
    #>

    [CmdletBinding()]
    [OutputType( [PSObject] )]

    param (

        # One or more UserNames to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String[]]
        $UserName
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
        $Query = "SELECT * FROM Users"
    }

    process {

        $QueryFilter = New-Object System.Collections.ArrayList
        foreach ($user in $UserName) {
            $null = $QueryFilter.Add(" UserName LIKE '$user'")
        }
    }

    end {

        if ($QueryFilter.Count -gt 0) {
            $Query += " WHERE"
            $Query += $QueryFilter -join ' OR '
        }
        $Query += ";"

        Write-Verbose "Get-ChocoStatUser: Execute SQL Query: $Query"

        $result = Invoke-SqliteQuery -Query $Query -Database $DbFile

        $result
    }
}
