function New-ChocoStatServerDatabase {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]

    param (
        [Parameter(Mandatory)]
        [String]
        $File,

        [Parameter()]
        [Switch]
        $Force
    )

    process {

        $createDBCode = {
            New-Item -ItemType Directory -Path (Split-Path -Path $File -Parent) -ErrorAction SilentlyContinue

            $Query = "CREATE TABLE Computers (ComputerID INTEGER NOT NULL PRIMARY KEY, ComputerName varchar(255) NOT NULL, LastContact DATETIME);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Packages (PackageID INTEGER NOT NULL PRIMARY KEY, PackageName varchar(255) NOT NULL);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Sources (SourceID INTEGER NOT NULL PRIMARY KEY, SourceURL varchar(255) NOT NULL);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE ComputerPasswords (ComputerID INTEGER NOT NULL, HashedPassword varchar(128) NOT NULL, PRIMARY KEY (ComputerID, HashedPassword));"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Computers_Sources (ComputerID INTEGER NOT NULL, SourceURL varchar(255) NOT NULL, SourceName varchar(255) NOT NULL, Enabled BOOLEAN NOT NULL, Priority INTEGER NOT NULL, ByPassProxy BOOLEAN NOT NULL, SelfService BOOLEAN NOT NULL, AdminOnly BOOLEAN NOT NULL, PRIMARY KEY (ComputerID, SourceName));"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Users (UserName varchar(255) NOT NULL PRIMARY KEY, HashedPassword varchar(128) NOT NULL);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE APITokens (APIToken varchar(36) NOT NULL PRIMARY KEY, UserName varchar(36) NOT NULL, Lifetime INTEGER NOT NULL, Type varchar(25) NOT NULL, WhenCreated int(11) NOT NULL);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Computers_Packages (ComputerID INTEGER NOT NULL, PackageID INTEGER NOT NULL, Version varchar(255) NOT NULL, Parameters varchar(255) NULL, InstalledOn varchar(255) NULL, PRIMARY KEY (ComputerID, PackageID) );"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Computers_FailedPackages (ComputerID INTEGER NOT NULL, PackageID INTEGER NOT NULL, Version varchar(255) NOT NULL, Parameters varchar(255) NULL, FailedOn varchar(255) NULL, PRIMARY KEY (ComputerID, PackageID) );"
            Invoke-SqliteQuery -Query $Query -Database $File
        }

        if ( (Test-Path -Path $File) -eq $False) {
            Invoke-Expression -Command $createDBCode.ToString()
        } elseif ( (Test-Path -Path $File -PathType Container)) {
            Throw "'$File' is a container, and cannot be used for creating a new database. Choose a file instead"
        } elseif ( (Test-Path -Path $File -PathType Leaf)) {
            if ($Force.IsPresent) {
                Remove-Item -Path $File -Force
                Invoke-Expression -Command $createDBCode.ToString()
            } else {
                Throw "'$File' does already exist. Choose a non-existing file name or use the '-Force'-Parameter to overwrite the file"
            }
        }

        $script:File = $File
        [System.IO.FileInfo]$File
    }

}
