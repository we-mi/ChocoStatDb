function Test-ComputerSecret {
    <#
    .SYNOPSIS
        Test the secret for a computer
    .DESCRIPTION
        Test the secret for a computer
    .NOTES
        Returns computer-object on success, False on failure
    .EXAMPLE
        Test-ComputerSecret -ComputerID 1 -Secret "mysecret"

        Checks if the secret for computer ID 1 is "mysecret"
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # The computerid to test
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerID,

        # The secret to test
        [Parameter(Mandatory)]
        [String]
        $Secret
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $Query = "SELECT HashedPassword FROM ComputerPasswords WHERE ComputerID = @ComputerID AND HashedPassword = @HashedPassword;"
        $results = Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
            ComputerID = $ComputerID
            HashedPassword = $Secret
        }

        if ($results.Count -eq 1) {
            return (Get-ChocoStatComputer -ComputerID $ComputerID)
        } elseif ($results.count -gt 1) {
            Throw "Multiple secrets for one computer id found. This cant be"
        } else {
            return $null
        }

    }
}
