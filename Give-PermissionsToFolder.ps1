Import-Module ActiveDirectory

function Grant-PermissionsToFolder {
        param (
            [string]$HomeDrivePath,
            [string]$HomeDriveFormat,
            [string]$NewUser,
            [string]$TargetFS,
            [pscredential]$credentials
        )
    Try {
        Invoke-Command -ComputerName $TargetFS -Credential $credentials -ScriptBlock {
        param (
            $HomeDrivePath,
            $HomeDriveFormat,
            $NewUser
        )
        $a = "H:\HOME\$HomeDriveFormat\$NewUser"
        $b = "$NewUser"

        $retry = 0

        do {
            icacls $a /grant "${b}:(OI)(CI)M" /t

            if ($LASTEXITCODE -eq 0) {
                break
            }

            Write-Host "AD w trakcie replikacji $b (błąd $LASTEXITCODE)" -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            $retry++
        } while ($retry -lt 5 -and $LASTEXITCODE -eq 1332)

        if ($LASTEXITCODE -ne 0) {
            Throw "icacls: wystąpił błąd z kodem $LASTEXITCODE."
        }

    } -ArgumentList $HomeDrivePath, $HomeDriveFormat, $NewUser, $TargetFS
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
