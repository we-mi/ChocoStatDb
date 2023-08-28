function Update-ChocoStatComputerPackage {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # ComputerID for adding the packages
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int]
        $ComputerID,

        # A PackageName which should be added to the computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $PackageName,

        # The version of the package
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $Version,

        [Parameter()]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $Parameters,

        [Parameter()]
        [datetime]
        $InstalledOn
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerPackageObject = Get-ChocoStatComputerPackage -ComputerID $ComputerID -PackageName $PackageName

        if ($ComputerPackageObject) {

            if ([String]::IsNullOrWhiteSpace($Version) -and [String]::IsNullOrWhiteSpace($Parameters) -and $null -eq $InstalledOn) {
                Write-Warning "Nothing to update"
                return $null
            }

            if ([String]::IsNullOrWhiteSpace($Version)) {
                $Version = $ComputerPackageObject.Version
            }

            if ([String]::IsNullOrWhiteSpace($Parameters)) {
                $Parameters = $ComputerPackageObject.Parameters
            }

            if ($null -eq $InstalledOn) {
                if ($null -eq $ComputerPackageObject.InstalledOn) {
                    $InstalledOn = [datetime]"1970-01-01"
                } else {
                    $InstalledOn = $ComputerPackageObject.InstalledOn
                }
            }

            $Query = "UPDATE Computers_Packages SET Version=@Version, Parameters=@Parameters, InstalledOn=@InstalledOn WHERE ComputerID=@ComputerID AND PackageID=@PackageID"
            Write-Verbose "Update-ChocoStatComputerFailedPackage: Execute SQL Query: $Query"

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerPackageObject.ComputerID
                PackageID = $ComputerPackageObject.PackageID
                Version = $Version
                Parameters = $Parameters
                InstalledOn = $InstalledOn
            }
        } else {
            $splat = @{
                ComputerID = $ComputerID
                PackageName = $PackageName
                Version = $Version
            }

            if (-not [String]::IsNullOrWhiteSpace($Parameters)) {
                $splat.Parameters = $Parameters
            }

            if ($null -ne $InstalledOn) {
                $splat.InstalledOn = $InstalledOn
            }

            Add-ChocoStatComputerPackage @splat
        }

    }

}
