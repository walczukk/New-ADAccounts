Import-Module ActiveDirectory

$HomeDrivePath
$NewUser

$a = "$($using:HomeDrivePath)\$($using:HomeDriveFormat)\$($using:NewUser)"
$b = "$($using:NewUser)$"
$c = "H:\HOME\$($using:HomeDriveFormat)\$($using:NewUser)"
function Grant-PermissionsToFolder {
    Invoke-Command -ComputerName "vm01" -Credential $credentials -ScriptBlock {
        icacls $a /t /grant $b:M
    }
}

function Add-SharingToFolder {
    $credentials
    Invoke-Command -ComputerName "vm01" -Credential $credentials -ScriptBlock {
        New-SmbShare -Name "$b" -Path "$c" -ChangeAccess "Wszyscy"
    }   
}
