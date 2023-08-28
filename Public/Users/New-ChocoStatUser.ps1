function New-ChocoStatUser {
    <#
    .SYNOPSIS
        Creates a new user in the database
    .DESCRIPTION
        Creates a new user in the database. You need to provide a password
    .NOTES
        The password is hashed with the SHA512-Algorithm and then stored in the database
    .EXAMPLE
        New-ChocoStatUser -UserName "bob" -Password "superstrongpassword"

        Creates a new user named "bob" with the password "superstrongpassword"
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # Name of the user
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String]
        $UserName,

        # Password of user
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String]
        $Password,

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
        $double = Get-ChocoStatUser -UserName $UserName
        if ($double.UserName -eq $UserName ) {
            Throw "UserName already existing."
        }

        $Query = "INSERT INTO Users (UserName, HashedPassword) VALUES (@UserName, @HashedPassword);"
        Write-Verbose "New-ChocoStatUser: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would create user with name '$UserName'"
        } else {
            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                UserName = $UserName
                HashedPassword = Get-Hash -InputString $Password
            }
        }

        if ($PassThru.IsPresent) {
            Get-ChocoStatUser -UserName $UserName
        }
    }
}
