function Get-ChocoStatComputer {
    <#
    .SYNOPSIS
        Lists computers in the ChocoStat-Database
    .DESCRIPTION
        Lists computers in the ChocoStat-Database depending on the filters. You can include packages, failed packages and sources which are attached to this computer
    .NOTES
        The output can be filtered by one or more ComputerIDs *OR* one or more ComputerNames which might contain SQL-Wildcards
    .LINK
        https://github.com/we-mi/ChocoStatDb/blob/main/docs/Get-ChocoStatComputer.md
    .EXAMPLE
        Get-ChocoStatComputer

        Lists all computers in the database
    .EXAMPLE
        Get-ChocoStatComputer -ComputerID 5

        Lists only the computer with the ID "5"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerID 5,7

        Lists only the computers with the ID "5" and "7"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName '%.example.org'

        Lists all computers which ends with `.example.org`
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName '%.example.org','%foo%'

        Lists all computers which ends with `.example.org` or which contains the word `foo`
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName '%.example.org' -Packages -FailedPackages -Sources

        Lists all computers which ends with `.example.org` and also shows attached packages, failed packages and sources for these computers
    #>

    [CmdletBinding(DefaultParameterSetName="ComputerName")]
    [OutputType([Object[]])]

    param (
        # One or more ComputerIDs to search for
        [Parameter(
            ParameterSetName = "ComputerID",
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $ComputerID,

        # One or more ComputerNames to search for (can contain SQL wildcards)
        [Parameter(
            ParameterSetName = "ComputerName",
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -match $Regex.PackageNameSQLWildcard } ) ]
        [String[]]
        $ComputerName,

        # Should the search include package information for computers?
        [Parameter()]
        [switch]
        $Packages,

        # Should the search include failed package information for computers?
        [Parameter()]
        [switch]
        $FailedPackages,

        # Should the search include source information for computers?
        [Parameter()]
        [switch]
        $Sources,

        # Path to the SQLite-Database. Leave empty to let `Get-ChocoStatDBFile` search for it automatically
        [Parameter()]
        [System.IO.FileInfo]
        $Database
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey("Database")) {
            $DbFile = Get-ChocoStatDBFile
        } else {
            $DbFile = $Database
        }

        $Query = [System.Collections.ArrayList]@()
        $null = $Query.Add("SELECT Computers.ComputerID,Computers.ComputerName,Computers.LastContact FROM Computers")
    }

    process {

        $QueryFilters = [System.Collections.ArrayList]@()

        foreach ($singleComputerID in $ComputerID) {
            $null = $QueryFilters.Add( "ComputerID = $singleComputerID" )
        }

        foreach ($singleComputerName in $ComputerName) {
            $null = $QueryFilters.Add( "ComputerName LIKE '$singleComputerName'" )
        }
    }

    end {
        if ($QueryFilters.Count -gt 0) {
            $null = $Query.Add(" WHERE ")
            $null = $Query.Add($QueryFilters -join ' OR ')
        }

        $null = $Query.Add(";")

        $FullSQLQuery = $Query -join ''

        Write-Debug "Get-ChocoStatComputer: Execute SQL Query: $FullSQLQuery"

        $result = [System.Collections.ArrayList]::new()
        $result.AddRange( (Invoke-SqliteQuery -Query $FullSQLQuery -Database $DbFile | Select-Object ComputerID,ComputerName,@{N='LastContact';E={ $_.LastContact.ToString() }}) )

        if ($Packages.IsPresent) {
            $ComputerPackages = [System.Collections.ArrayList]::new()
            $ComputerPackages.AddRange( (Get-ChocoStatComputerPackage -ComputerID $result.ComputerID) )

            $result | Add-Member -MemberType NoteProperty -Name Packages -Value $null
            foreach ($computer in $result) {
                $computer.Packages = $ComputerPackages.Where( { $_.ComputerID -eq $computer.ComputerID } ) | Select-Object PackageName,Version,InstalledOn
            }
        }

        if ($FailedPackages.IsPresent) {
            $ComputerFailedPackages = [System.Collections.ArrayList]::new()
            $ComputerFailedPackages.AddRange( (Get-ChocoStatComputerFailedPackage -ComputerID $result.ComputerID) )

            $result | Add-Member -MemberType NoteProperty -Name FailedPackages -Value $null
            foreach ($computer in $result) {
                $computer.FailedPackages = $ComputerFailedPackages.Where( { $_.ComputerID -eq $computer.ComputerID } ) | Select-Object PackageName,Version,FailedOn
            }
        }

        if ($Sources.IsPresent) {
            $ComputerSources = [System.Collections.ArrayList]::new()
            $ComputerSources.AddRange( (Get-ChocoStatComputerSource -ComputerID $result.ComputerID) )

            $result | Add-Member -MemberType NoteProperty -Name Sources -Value $null
            foreach ($computer in $result) {
                $computer.Sources = $ComputerSources.Where( { $_.ComputerID -eq $computer.ComputerID } ) | Select-Object SourceName,SourceURL,Enabled,Priority,ByPassProxy,SelfService,AdminOnly
            }
        }

        if ($result.Count -eq 1) {
            return ,@($result)
        } else {
            return $result
        }
    }
}
