function Update-ChocoStatComputerFailedPackage {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # ComputerID for adding the failed packages
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int]
        $ComputerID,

        # A PackageName which should be added to the computer as a failed package
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
        $FailedOn
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerFailedPackageObject = Get-ChocoStatComputerFailedPackage -ComputerID $ComputerID -PackageName $PackageName

        if ($ComputerFailedPackageObject) {

            if ([String]::IsNullOrWhiteSpace($Version) -and [String]::IsNullOrWhiteSpace($Parameters) -and $null -eq $FailedOn) {
                Write-Warning "Nothing to update"
                return $null
            }

            if ([String]::IsNullOrWhiteSpace($Version)) {
                $Version = $ComputerFailedPackageObject.Version
            }

            if ([String]::IsNullOrWhiteSpace($Parameters)) {
                $Parameters = $ComputerFailedPackageObject.Parameters
            }

            if ($null -eq $FailedOn) {
                if ($null -eq $ComputerFailedPackageObject.InstalledOn) {
                    $FailedOn = [datetime]"1970-01-01"
                } else {
                    $FailedOn = $ComputerFailedPackageObject.InstalledOn
                }
            }

            $Query = "UPDATE Computers_FailedPackages SET Version=@Version, Parameters=@Parameters, FailedOn=@FailedOn WHERE ComputerID=@ComputerID AND PackageID=@PackageID"
            Write-Verbose "Update-ChocoStatComputerFailedPackage: Execute SQL Query: $Query"

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerFailedPackageObject.ComputerID
                PackageID = $ComputerFailedPackageObject.PackageID
                Version = $Version
                Parameters = $Parameters
                FailedOn = $FailedOn
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

            if ($null -ne $FailedOn) {
                $splat.InstalledOn = $FailedOn
            }

            Add-ChocoStatComputerFailedPackage @splat
        }

    }

}
