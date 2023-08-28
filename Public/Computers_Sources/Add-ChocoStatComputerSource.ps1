# TODO:
#  Check if Source already added -> helpful error message and use Update-ChocoStatComputerSource
function Add-ChocoStatComputerSource {
    <#
    .SYNOPSIS
        Adds a Source to a computer
    .DESCRIPTION
        Adds a Source to a computer. You cannot have multiple sources with the same name added to one computer
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName "foo.example.org" | Add-ChocoStatComputerSource -SourceName "chocolatey" -SourceUrl "https://chocolatey.org/api/v2/" -Enabled -Priority 1

        Adds the Source named "chocolatey" with the url "https://chocolatey.org/api/v2/" and the "Enabled"-Status to the computer "foo.example.org"
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # ComputerID for adding the Sources
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int]
        $ComputerID,

        # A SourceName which should be added to the computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $SourceName,

        # A SourceName which should be added to the computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String]
        $SourceURL,

        # Source priority, lower number means higher priority
        [Parameter()]
        [ValidateRange(0,100)]
        [Int]
        $Priority = 0,

        # Is the source enabled? Defaults to true
        [Parameter()]
        [bool]
        $Enabled = $true,

        # Using a proxy? Defaults to false
        [Parameter()]
        [bool]
        $ByPassProxy = $false,

        [Parameter()]
        [bool]
        $SelfService = $false,

        # Dont actually do anything
        [Parameter()]
        [bool]
        $AdminOnly = $false,

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerObject = Get-ChocoStatComputer -ComputerID $ComputerID -Sources

        if ($null -eq $ComputerObject) {
            Throw "Computer with ID '$ComputerID' does not exist"
        }

        if ($ComputerObject.Sources.SourceName -contains $SourceName) {
            Throw "Source '$SourceName' already attached to computer with ID '$ComputerID'"
        }

        $Query = "INSERT INTO Computers_Sources (ComputerID, SourceName, SourceURL, Enabled, Priority, ByPassProxy, SelfService, AdminOnly) VALUES (@ComputerID, @SourceName, @SourceURL, @Enabled, @Priority, @ByPassProxy, @SelfService, @AdminOnly)"
        Write-Verbose "Add-ChocoStatComputerSource: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would add Source '$SourceName' to computer with ID '$ComputerID'"
        } else {

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerObject.ComputerID
                SourceName = $SourceName
                SourceURL = $SourceURL
                Enabled = $Enabled
                Priority = $Priority
                ByPassProxy = $ByPassProxy
                SelfService = $SelfService
                AdminOnly = $AdminOnly
            }
        }
    }
}
