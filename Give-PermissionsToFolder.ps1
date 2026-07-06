Import-Module ActiveDirectory

function Grant-PermissionsToFolder {
        param (
            [string]$HomeDriveFormat,
            [string]$CreatedUserSID,
            [string]$NewUser,
            [string]$TargetFS,
            [pscredential]$credentials
        )
    Try {
        Invoke-Command -ComputerName $TargetFS -Credential $credentials -ScriptBlock {
        param (
            $HomeDriveFormat,
            $CreatedUserSID,
            $NewUser
        )
        $a = "H:\HOME\$HomeDriveFormat\$NewUser"
        New-Item -Path $a -ItemType Directory -Force
        icacls $a /grant "*${CreatedUserSID}:(OI)(CI)M" /t #uprawnienia RWX

        if ($LASTEXITCODE -ne 0) {
            Throw "icacls: wystąpił błąd z kodem $LASTEXITCODE."
        }

    } -ArgumentList $HomeDriveFormat, $CreatedUserSID, $NewUser, $TargetFS
} Catch {
    Write-Host "BŁĄD $($_.Exception.Message)" -BackgroundColor Red
}
}

function Add-SharingToFolder {
        param (
            [string]$HomeDriveFormat,
            [string]$NewUser,
            [string]$TargetFS,
            [pscredential]$credentials
        )
    Try {
        Invoke-Command -ComputerName $TargetFS -Credential $credentials -ScriptBlock {
        param (
            $HomeDriveFormat,
            $NewUser
        )
        
        $b = "$NewUser$"
        $c = "H:\HOME\$HomeDriveFormat\$NewUser"

        New-SmbShare -Name "$b" -Path "$c" -ChangeAccess "Wszyscy"
    } -ArgumentList $HomeDriveFormat, $NewUser, $TargetFS
} Catch {
    Write-Host "BŁĄD $($_.Exception.Message)" -BackgroundColor Red
}
}
