function Get-ChocoStatDBFile {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {
        if ( -not [String]::IsNullOrWhiteSpace($env:ChocoStatDbFile) ) {
            return $env:ChocoStatDbFile
        } elseif ($global:ChocoStatDbFile) {
            return $global:ChocoStatDbFile
        } elseif ($script:ChocoStatDbFile) {
            return $script:ChocoStatDbFile
        } else {
            Throw "No location for ChocoStat database file found"
        }
    }

    end {

    }
}
