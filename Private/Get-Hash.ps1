function Get-Hash {
    [CmdletBinding()]
    param (
        # String to be converted to a hash
        [Parameter(Mandatory)]
        [AllowEmptyString()][AllowNull()]
        [String]
        $InputString
    )

    begin {

    }

    process {
        if ( [String]::IsNullOrWhiteSpace($InputString) ) {
            return $null
        } else {
            $pwstream = [IO.MemoryStream]::new([byte[]][char[]]$InputString)
            $HashedPassword = Get-FileHash -InputStream $pwstream -Algorithm SHA512 | Select-Object -ExpandProperty Hash

            return $HashedPassword
        }
    }

    end {

    }
}
