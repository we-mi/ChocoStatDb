function New-ChocoStatAPIToken {
    <#
    .SYNOPSIS
        Creates a new API-Token for a user in the database
    .DESCRIPTION
        Creates a new API-Token for a user in the database. You can provide a lifetime and a type
    .NOTES
        The default lifetime is 1 year, the default type is "read"
    .EXAMPLE
        New-ChocoStatAPIToken -UserName "bob" -LifeTime "31" -Type write

        Creates a new API-Token for the user with the given name, with a lifetime of 31 days and the type "write" which allows the user to modify computers, packages, and sources
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # ID of the user
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String]
        $UserName,

        # Lifetime of the API-Token
        [Parameter()]
        [timespan]
        $Lifetime = "365",

        <# Lifetime of the API-Token
        read = Can read computers, packages, sources and their relations
        write = same as read, but can modify this data
        admin = Can read/write everything including user data
        #>
        [Parameter()]
        [ValidateSet("read","write","admin")]
        [String]
        $Type = "read",

        # Return the newly created object
        [Parameter()]
        [Switch]
        $PassThru
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $UserObject = Get-ChocoStatUser -UserName $UserName
        if ( -not $UserObject) {
            Throw "User with Name '$UserName' does not exist"
        }

        do {
            $APIToken = (New-Guid).Guid
        } while ( (Get-ChocoStatAPIToken).APIToken -contains $APIToken )


        $Query = "INSERT INTO APITokens (APIToken, UserName, Lifetime, Type, WhenCreated) VALUES (@APIToken, @UserName, @LifeTime, @Type, @WhenCreated);"
        Write-Verbose "New-ChocoStatAPIToken: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would create API-Token '$APIToken'"
        } else {
            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                UserName = $UserName
                APIToken = $APIToken
                Lifetime = $Lifetime.TotalDays
                Type = $Type
                WhenCreated = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            }
        }

        if ($PassThru.IsPresent) {
            Get-ChocoStatAPIToken -APIToken $APIToken
        }
    }
}
