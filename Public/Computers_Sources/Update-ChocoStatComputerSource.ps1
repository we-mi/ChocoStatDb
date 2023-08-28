function Update-ChocoStatComputerSource {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # ComputerID for updating the source
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int]
        $ComputerID,

        # Which source should be updated?
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $SourceName,

        # A SourceURL which should be updated for the computer
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String]
        $SourceURL,

        # Source priority, lower number means higher priority
        [Parameter()]
        [ValidateRange(0,100)]
        [Int]
        $Priority,

        # Is the source enabled? Defaults to true
        [Parameter()]
        [bool]
        $Enabled,

        # Using a proxy? Defaults to false
        [Parameter()]
        [bool]
        $ByPassProxy,

        [Parameter()]
        [bool]
        $SelfService,

        # Dont actually do anything
        [Parameter()]
        [bool]
        $AdminOnly
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerSourceObject = Get-ChocoStatComputerSource -ComputerID $ComputerID -SourceName $SourceName

        if ($ComputerSourceObject) {

            $Parameters = $PSBoundParameters.Keys
            if ($Parameters -notcontains "SourceURL" -and $Parameters -notcontains "Enabled" -and $Parameters -notcontains "Priority" -and $Parameters -notcontains "ByPassProxy" -and $Parameters -notcontains "SelfService" -and $Parameters -notcontains "AdminOnly") {
                Write-Warning "Nothing to update"
                return $null
            }

            if ( [String]::IsNullOrWhiteSpace($SourceURL) ) {
                $SourceURL = $ComputerSourceObject.SourceURL
            }

            if ($Parameters -notcontains "Priority") {
                $Priority = $ComputerSourceObject.Priority
            }

            if ($Parameters -notcontains "Enabled") {
                $Enabled = $ComputerSourceObject.Priority
            }

            if ($Parameters -notcontains "ByPassProxy") {
                $ByPassProxy = $ComputerSourceObject.Priority
            }

            if ($Parameters -notcontains "SelfService") {
                $SelfService = $ComputerSourceObject.Priority
            }

            if ($Parameters -notcontains "AdminOnly") {
                $AdminOnly = $ComputerSourceObject.Priority
            }

            $Query = "UPDATE Computers_Sources SET SourceURL=@SourceURL, Enabled=@Enabled, Priority=@Priority, ByPassProxy=@ByPassProxy, SelfService=@SelfService, AdminOnly=@AdminOnly WHERE ComputerID=@ComputerID AND SourceName=@SourceName;"

            Write-Verbose "Update-ChocoStatComputerSource: Execute SQL Query: $Query"

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerSourceObject.ComputerID
                SourceName = $SourceName
                SourceURL = $SourceURL
                Enabled = $Enabled
                Priority = $Priority
                ByPassProxy = $ByPassProxy
                SelfService = $SelfService
                AdminOnly = $AdminOnly
            }
        } else {

            if ( [String]::IsNullOrWhiteSpace($SourceURL) ) {
                Throw "You need a SourceURL if you want to call this cmdlet on a non existing-computer in order to create the computer"
            }

            $splat = @{
                ComputerID = $ComputerID
                SourceName = $SourceName
                SourceURL = $SourceURL
            }

            if ($Parameters -contains "Priority") {
                $splat.Priority = $Priority
            }

            if ($Parameters -contains "Enabled") {
                $splat.Enabled = $Enabled
            }

            if ($Parameters -contains "ByPassProxy") {
                $splat.ByPassProxy = $ByPassProxy
            }

            if ($Parameters -contains "SelfService") {
                $splat.SelfService = $SelfService
            }

            if ($Parameters -contains "AdminOnly") {
                $splat.AdminOnly = $AdminOnly
            }

            Add-ChocoStatComputerSource @splat
        }

    }

}
