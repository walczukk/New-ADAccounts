<#
.SYNOPSIS
Dodaje użytkowników "user" do Active Directory

.DESCRIPTION
Skrypt pobiera ostatni numer identyfikatora "user", następnie na podstawie zdefiniowanej
liczby, generuje ilość nowych kont użytkowników w AD oraz dodaje je do wskazanych grup.

.EXAMPLE
.\New-ADAccounts_v1.2.ps1 -Count 10

.NOTES
    Wersja: 1.2
    Autor: Kacper Walczuk | kacper@walcz.uk
    Data publikacji: 2026-06-22

    ZASTRZEŻENIE
    Skrypt wprowadza zmiany w Active Directory. Mimo że został napisany z dbałością o błędy,
    używasz ich na własną odpowiedzialność! Przetestuj dokładnie jego działanie na środowisku
    testowym przed uruchomieniem go na produkcji :) 
#>
[CmdletBinding()]
param (
    [string]$UserPrefix = "user",
    [string]$DomainSuffix = "domain.pl",
    [string]$TargetOU = "OU=Users,DC=domain,DC=pl",
    [string[]]$TargetGroups = @("gg-group1","gg-group2"),
    [string]$LogPath = "C:\scripts\New-ADAccounts\logs",
    [string]$TargetFS = "vm01",
    [int]$Count = 2
)

Import-Module ActiveDirectory

$credentials = Get-Credential -Message "Podaj poświadczenia administratorskie"

$UserList = Get-ADUser -Filter "Name -like '$UserPrefix*'" -SearchBase $TargetOU | 
    Sort-Object {[int]($_.Name -replace "$UserPrefix", '')} | 
    Select -ExpandProperty Name -Last 1

$StartNumber =  [int]($UserList -replace $UserPrefix, '')
$DateFormat = Get-Date -Format 'yyyy_MM_dd'
$LogFile = Join-Path -Path $LogPath -ChildPath "Accounts_Import_$DateFormat.log"

if (!(Test-Path -Path $LogPath)){
    mkdir $LogPath
}

Try {
    Invoke-Command -Credential $credentials -ComputerName $TargetFS -ScriptBlock { hostname } -ErrorAction Stop
} Catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "BŁĄD: $TargetFS nie ma włączonej funkcji zdalnego zarządzania! 
    Uruchom Enable-PSRemoting na $TargetFS - $ErrorMessage" -BackgroundColor Red
    "$($DateFormat): BŁĄD: $TargetFS nie ma włączonej funkcji zdalnego zarządzania! 
    Uruchom Enable-PSRemoting na $TargetFS - $ErrorMessage" | Out-File -FilePath $LogFile -Append

    exit 1
}

$NewNumber = for ($i = 1; $i -le $Count; $i++) {
    $StartNumber + $i
}

foreach ($num in $NewNumber) {
    $NewUser = "{0}{1:D4}" -f $UserPrefix, $num
    Write-Host "Dodaję $NewUser..."

    Try {
        $Password = ConvertTo-SecureString "P@ssW0rdPassw0rD123" -AsPlainText -Force
        Start-Sleep -Milliseconds 300

        New-ADUser -Credential $credentials `
                   -Name $NewUser `
                   -SAMAccountName $NewUser `
                   -Path $TargetOU `
                   -Enabled $false `
                   -AccountPassword $Password `
                   -UserPrincipalName $NewUser@$DomainSuffix `
                   -Description $NewUser `
                   -ScriptPath "script.bat" `
                   -HomeDrive "H:" `
                   -HomeDirectory "\\$TargetFS\$NewUser$" `
                   #-WhatIf

        Write-Host "Dodałem $NewUser" -ForegroundColor Green
        "$($DateFormat): Dodano $NewUser" | Out-File -FilePath $LogFile -Append
        Start-Sleep -Seconds 1

        #dodanie użytkownika do grup
        foreach ($group in $TargetGroups) {
            Add-ADGroupMember -Credential $credentials -Identity $group -Members $NewUser #-WhatIf
            Write-Host "Dodałem $NewUser do grupy: $group" -BackgroundColor Cyan
            "$($DateFormat): Dodano $NewUser do grupy: $group" | Out-File -FilePath $LogFile -Append
        }

        #weryfikacja istnienia folderu Kxxxx na FileServerze
        $HomeDrivePath = "\\$TargetFS\HOME$\"
        $ParentSuffix = [Math]::Floor($num / 100) * 100
        $HomeDriveFormat = "K{0:D4}" -f [int]$ParentSuffix        
        $HomeDriveChildPath = Join-Path -Path $HomeDrivePath -ChildPath $HomeDriveFormat

        if (Test-Path $HomeDriveChildPath -PathType Container) {
            #jeśli istnieje - nie rób nic
        } else {
            Write-Host "Nie istnieje $HomeDriveChildPath - tworzę nowy folder..."
            Start-Sleep -Milliseconds 500

            New-Item -Path $HomeDrivePath -Name $HomeDriveFormat -ItemType Directory
            Write-Host "Utworzyłem $HomeDriveChildPath!"

        }

        if (Test-Path $HomeDriveChildPath -PathType Container) {
            Write-Host "Tworzę folder $NewUser..."
            Start-Sleep -Milliseconds 500

            New-Item -Path $HomeDriveChildPath -Name $NewUser -ItemType Directory
            Start-Sleep -Seconds 2

            . "$PSScriptRoot\Give-PermissionsToFolder.ps1"

            Grant-PermissionsToFolder `
                -HomeDrivePath $HomeDrivePath `
                -HomeDriveFormat $HomeDriveFormat `
                -NewUser $NewUser `
                -credentials $credentials `
                -TargetFS $TargetFS

            Start-Sleep -Seconds 1

            Add-SharingToFolder `
                -HomeDriveFormat $HomeDriveFormat `
                -NewUser $NewUser `
                -credentials $credentials `
                -TargetFS $TargetFS

            Write-Host "Utworzyłem folder $NewUser!"
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "BŁĄD przy $NewUser - $ErrorMessage" -BackgroundColor Red
        "$($DateFormat): BŁĄD przy $NewUser - $ErrorMessage" | Out-File -FilePath $LogFile -Append
    }
}
