function New-ChocoStatComputer {
    <#
    .SYNOPSIS
        Creates a new computer in the database
    .DESCRIPTION
        Creates a new computer in the database. You can choose to pass the LastContact date or leave it out, then it will default to the current time
    .EXAMPLE
        New-ChocoStatComputer -ComputerName "foo.example.org"

        Creates a new computer "foo.example.org" and set the LastContact date to the current date
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # Name of the computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $ComputerName,

        # Secret for the computer. This can be used to later identify a computer which can update itself
        [Parameter(
            Mandatory
        )]
        [String]$Secret,

        # Date of last contact
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [datetime]
        $LastContact = (Get-Date),

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
        $double = Get-ChocoStatComputer -ComputerName $ComputerName
        if ($double.ComputerName -eq $ComputerName) {
            Throw "Computername already present"
        }

        $Query = "INSERT INTO Computers (ComputerName, LastContact) VALUES (@ComputerName,@LastContact);"
        Write-Verbose "New-ChocoStatComputer: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would create computer with name '$ComputerName'"
        } else {
            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerName = $ComputerName
                LastContact = $LastContact
                HashedPassword = Get-Hash -InputString $Secret
            }
        }

        $computer = Get-ChocoStatComputer | Where-Object { $_.ComputerName -eq $ComputerName }

        $Query = "INSERT INTO ComputerPasswords (ComputerID, HashedPassword) VALUES (@ComputerID,@HashedPassword);"
        Write-Verbose "New-ChocoStatComputer: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would set secret for computer with ID '$($computer.ComputerID)'"
        } else {
            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $Computer.ComputerID
                HashedPassword = Get-Hash -InputString $Secret
            }
        }


        if ($PassThru.IsPresent) {
            $computer
        }
    }
}

