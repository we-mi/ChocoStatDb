function Update-ChocoStatUser {
    <#
    .SYNOPSIS
        Updates a user in the database
    .DESCRIPTION
        Currently only updating the password is supported
        If the user you wish to update does not exist yet, you can enforce its creation with the '-Force' parameter.
    .NOTES
        This cmdlet will throw an error if a new user should be created and the name does already exist.
    .EXAMPLE
        Update-ChocoStatUser -UserName "BetterBob" "mysuperstrongpassword"

        Will change the for User "BetterBob". The user will not be created if it does not exist.
    .EXAMPLE
        Update-ChocoStatUser -UserName "BetterBob" -Password "StrongerPassword123$" -Force
        Will create the user "BetterBob" if the user does not exist yet.
    #>
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # name of the user
        [Parameter(Mandatory)]
        [String]
        $UserName,

        # New password of the user
        [Parameter()]
        [String]
        $NewPassword,

        # The updated (or newly created user object) will be returned
        [Parameter()]
        [Switch]
        $PassThru,

        # Used when this cmdlet should create a user that was not found with its ID
        [Parameter()]
        [Switch]
        $Force,

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        if ([String]::IsNullOrWhiteSpace($Password)) {
            Throw "Nothing to insert or update. Gimme some password"
        }

        $UserObject = Get-ChocoStatUser -UserName $UserName

        if ($null -ne $UserObject) { # update existing object
            Write-Verbose "Update-ChocoStatUser: User with name '$UserName' was found. Update its password"

            $Query = "UPDATE Users SET "

            $Params = @()
            if ( -not [String]::IsNullOrWhiteSpace($NewPassword) ) {
                $Params += "HashedPassword=@HashedPassword"
            }
            $Query += $Params -join ','
            $Query += " WHERE UserName=@UserName"

            Write-Debug -Message "Update-ChocoStatUser: Execute SQL Query: $Query"
            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would update user with Name '$UserName'"
            } else {
                Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                    HashedPassword = Get-Hash -InputString $NewPassword
                }
            }

            if ($PassThru.IsPresent) {
                Get-ChocoStatUser -UserName $UserName
            }

        } else { # create new object (needs -Force and -NewUserName and -NewPassword at least)
            Write-Verbose "Update-ChocoStatUser: User with name '$UserName' was not found. Check if we should enforce its creation"
            if (-not $Force.IsPresent) {
                Throw "User with Name '$UserName' does not exist. Use -Force to create it nevertheless"
            }

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would create new user with name '$UserName'"
            } else {
                if ($PassThru.IsPresent) {
                    New-ChocoStatUser -UserName $UserName -Password $NewPassword -PassThru
                } else {
                    New-ChocoStatUser -UserName $UserName -Password $NewPassword
                }
            }
        }
    }
}
