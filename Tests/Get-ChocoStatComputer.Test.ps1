BeforeAll {
    Import-Module (Join-Path $PSScriptRoot "..\ChocoStatDb.psd1") -ErrorAction Stop -Force

    $null = New-ChocoStatServerDatabase -File (Join-Path $env:Temp "ChocoStatistics-Pester-Empty.db") -Force
    $null = New-ChocoStatServerDatabase -File (Join-Path $env:Temp "ChocoStatistics-Pester-OneComputer.db") -Force
    $null = New-ChocoStatServerDatabase -File (Join-Path $env:Temp "ChocoStatistics-Pester-OnePackage.db") -Force
    $null = New-ChocoStatServerDatabase -File (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db") -Force

    # Fill database with demo data
    $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
    for ($i = 0; $i -lt 10; $i++) {
        Write-Host "Creating demo computer $i"
        $computer = New-ChocoStatComputer -ComputerName "Computer-$i" -PassThru -Secret (Get-Random)

        for ($j = 0; $j -lt (Get-Random -Maximum 5); $j++) {
            Write-Host "  Attaching demo package to computer $i"
            $Package = @{PackageName = "Package-$(Get-Random -Maximum 20)"; Version = Get-Random }

            Update-ChocoStatComputerPackage -ComputerID $computer.ComputerID -PackageName $Package.PackageName -Version $Package.Version
        }

        for ($j = 0; $j -lt (Get-Random -Maximum 3); $j++) {
            $Package = @{PackageName = "Package-$(Get-Random -Maximum 20)"; Version = Get-Random }

            Update-ChocoStatComputerFailedPackage -ComputerID $computer.ComputerID -PackageName $Package.PackageName -Version $Package.Version
        }
    }

    $env:ChocoStatDbFile = $null

}

Describe 'Get-ChocoStatComputer' {

    Context 'Empty Database' {

        It 'Result should be empty' {
            $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-Empty.db")
            $computers = Get-ChocoStatComputer
            $computers | Should -Be $null
        }

    }

    Context 'Demo Database' {

        Context "No Parameters" {

            It 'Result should be an array' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                Write-Output -NoEnumerate $computers | Should -BeOfType [array]
            }

            It 'Result should have 10 elements' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                $computers.Count | Should -Be 10
            }

            It 'ID Property should be a number' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                $computers | ForEach-Object { $_.ComputerID | Should -BeOfType [Int64] }
            }

            It 'Name Property should be a string' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                $computers | ForEach-Object { $_.ComputerName | Should -BeOfType [String] }
            }

            It 'LastContact Property should be convertable to a DateTime' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                $computers | ForEach-Object { [DateTime]::ParseExact($_.LastContact,"dd.MM.yyyy HH:mm:ss", $null) | Should -BeOfType [DateTime] }
            }

            It '5th Element should be "Computer-4" with ID "5"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                $computers[4].ComputerID | Should -Be 5
                $computers[4].ComputerName | Should -Be "Computer-4"
            }

            It 'Result should not have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Packages"
            }

            It 'Result should not have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "FailedPackages"
            }

            It 'Result should not have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Sources"
            }

        }

        Context "ComputerID filtering" {

            It 'Result should be an array' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 1
                Write-Output -NoEnumerate $computers | Should -BeOfType [array]
            }

            It 'Query 1 ID should return 1 element' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 7
                $computers.Count | Should -Be 1
            }

            It 'Query 10 ID should return 10 elements' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID (1..10)
                $computers.Count | Should -Be 10
            }

            It 'ID Property should be a number' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 7
                $computers | ForEach-Object { $_.ComputerID | Should -BeOfType [Int64] }
            }

            It 'Name Property should be a string' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 7
                $computers | ForEach-Object { $_.ComputerName | Should -BeOfType [String] }
            }

            It 'LastContact Property should be convertable to a DateTime' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 7
                $computers | ForEach-Object { [DateTime]::ParseExact($_.LastContact,"dd.MM.yyyy HH:mm:ss", $null) | Should -BeOfType [DateTime] }
            }

            It 'Filtering element with ID 5 should be "Computer-5" with ID "5"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 5
                $computers.ComputerID | Should -Be 5
                $computers.ComputerName | Should -Be "Computer-4"
            }

            It 'Result should not have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 1
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Packages"
            }

            It 'Result should not have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 1
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "FailedPackages"
            }

            It 'Result should not have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerID 1
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Sources"
            }

        }

        Context "ComputerName filtering" {

            It 'Result should be an array' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-1"
                Write-Output -NoEnumerate $computers | Should -BeOfType [array]
            }

            It 'Query 1 Name should return 1 element' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-5"
                $computers.Count | Should -Be 1
            }

            It 'Query per wildcard should return 10 elements' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-%"
                $computers.Count | Should -Be 10
            }

            It 'ID Property should be a number' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-5"
                $computers | ForEach-Object { $_.ComputerID | Should -BeOfType [Int64] }
            }

            It 'Name Property should be a string' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-5"
                $computers | ForEach-Object { $_.ComputerName | Should -BeOfType [String] }
            }

            It 'LastContact Property should be convertable to a DateTime' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-5"
                $computers | ForEach-Object { [DateTime]::ParseExact($_.LastContact,"dd.MM.yyyy HH:mm:ss", $null) | Should -BeOfType [DateTime] }
            }

            It 'Filtering element with Name "Computer-4" should be "Computer-5" with ID "5"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-4"
                $computers.ComputerID | Should -Be 5
                $computers.ComputerName | Should -Be "Computer-4"
            }

            It 'Result should not have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-4"
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Packages"
            }

            It 'Result should not have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-4"
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "FailedPackages"
            }

            It 'Result should not have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -ComputerName "Computer-4"
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Sources"
            }

        }

        Context "Include Package information" {

            It 'Result should have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "Packages"
            }

            It 'Result should not have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "FailedPackages"
            }

            It 'Result should not have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Sources"
            }

        }

        Context "Include FailedPackage information" {

            It 'Result should not have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -FailedPackages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Packages"
            }

            It 'Result should have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -FailedPackages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "FailedPackages"
            }

            It 'Result should not have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -FailedPackages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Sources"
            }

        }

        Context "Include Source information" {

            It 'Result should not have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Packages"
            }

            It 'Result should not have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "FailedPackages"
            }

            It 'Result should have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "Sources"
            }

        }

        Context "Include Package and FailedPackage information" {

            It 'Result should have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages -FailedPackages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "Packages"
            }

            It 'Result should have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages -FailedPackages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "FailedPackages"
            }

            It 'Result should not have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages -FailedPackages
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Sources"
            }

        }

        Context "Include Package and Source information" {

            It 'Result should have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "Packages"
            }

            It 'Result should not have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "FailedPackages"
            }

            It 'Result should have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -Packages -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "Sources"
            }

        }

        Context "Include FailedPackage and Source information" {

            It 'Result should not have property "Packages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -FailedPackages -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Not -Contain "Packages"
            }

            It 'Result should have property "FailedPackages"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -FailedPackages -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "FailedPackages"
            }

            It 'Result should have property "Sources"' {
                $env:ChocoStatDbFile = (Join-Path $env:Temp "ChocoStatistics-Pester-TestData.db")
                $computers = Get-ChocoStatComputer -FailedPackages -Sources
                ($computers | Get-Member -MemberType NoteProperty).Name | Should -Contain "Sources"
            }

        }

    }
}
