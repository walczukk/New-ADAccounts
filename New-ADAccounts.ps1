Import-Module ActiveDirectory

cd C:\scripts\New-ADAccounts

$credentials = Get-Credential -Message "Podaj poświadczenia administratorskie"

$UserList = Get-ADUser -Filter 'Name -like "user*"' -SearchBase "OU=Users,DC=domain,DC=pl" | Sort-Object {[int]($_.Name -replace 'user', '')} | Select -ExpandProperty Name -Last 1
$StartNumber =  [int]($UserList -replace 'user', '')
$DateFormat = Get-Date -Format 'yyyy_MM_dd'

$LogPath = "C:\scripts\New-ADAccounts\logs\Accounts_Import_$DateFormat.log"

if (!(Test-Path "C:\scripts\New-ADAccounts\logs\")){
    New-Item -ItemType Directory -Path "C:\scripts\New-ADAccounts\" -Name "logs"
}

$NewNumber = 
for ($i = 1; $i -lt 2; $i++) {
    $StartNumber + $i
}

foreach ($num in $NewNumber) {
    $NewUser = "user$num"
    Write-Host "Dodaję $NewUser..."

    Try {
        $OU = "OU=Users,DC=domain,DC=pl"
        $Groups = @("gg-group1","ug-group1")
        $SAMAccountName = "$NewUser"
        $UPN = "$NewUser@domain.pl"
        $Password = ConvertTo-SecureString "P@ssW0rdPassw0rD123" -AsPlainText -Force
        Start-Sleep -Milliseconds 300

        New-ADUser -Name $NewUser `
                   -SAMAccountName $SAMAccountName `
                   -Path $OU `
                   -Enabled $false `
                   -AccountPassword $Password `
                   -UserPrincipalName $UPN `
                   -Description $NewUser `
                   -ScriptPath "script.bat" `
                   -HomeDrive "H:" `
                   -HomeDirectory "\\vm01\$NewUser" `
                   #-WhatIf

        Write-Host "Dodałem $NewUser" -ForegroundColor Green
        "$($DateFormat): Dodano $NewUser" | Out-File -FilePath $LogPath -Append
        Start-Sleep -Seconds 1

        #dodanie użytkownika do grup
        foreach ($group in $Groups) {
            Add-ADGroupMember -Identity $group -Members $SAMAccountName #-WhatIf
            Write-Host "Dodałem $NewUser do grupy: $group" -BackgroundColor Cyan
            "$($DateFormat): Dodano $NewUser do grupy: $group" | Out-File -FilePath $LogPath -Append
        }

        #weryfikacja istnienia folderu Kxxxx na FileServerze
        $HomeDrivePath = "\\vm01\HOME$\"
        $ParentSuffix = [Math]::Floor($num / 100) * 100
        $HomeDriveFormat = "K{0:D4}" -f [int]$ParentSuffix        
        $HomeDriveChildPath = Join-Path -Path $HomeDrivePath -ChildPath $HomeDriveFormat

        if (!(Test-Path $HomeDriveChildPath -PathType Container)) {
            Write-Host "Nie istnieje $HomeDriveChildPath - tworzę nowy folder..."
            Start-Sleep -Milliseconds 500

            New-Item -Path $HomeDrivePath -Name $HomeDriveFormat -ItemType Directory
            Write-Host "Utworzyłem $HomeDriveChildPath!"
        } else {
            Write-Host "Folder $HomeDriveFormat istnieje - przechodzę dalej..."
            Start-Sleep -Seconds 1
        }

        if (Test-Path $HomeDriveChildPath -PathType Container) {
            Write-Host "Tworzę folder $NewUser..."
            Start-Sleep -Milliseconds 500

            New-Item -Path $HomeDriveChildPath -Name $NewUser -ItemType Directory
            Start-Sleep -Seconds 2

            . .\Give-PermissionsToFolder.ps1

            Grant-PermissionsToFolder
            Start-Sleep -Seconds 1
            Add-SharingToFolder

            Write-Host "Utworzyłem folder $NewUser!"
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "BŁĄD przy $NewUser - $ErrorMessage" -BackgroundColor Red
        "$($DateFormat): BŁĄD przy $NewUser - $ErrorMessage" | Out-File -FilePath $LogPath -Append
    }
}
