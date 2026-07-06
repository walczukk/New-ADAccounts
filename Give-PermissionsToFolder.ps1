Import-Module ActiveDirectory

function Grant-PermissionsToFolder {
    $HomeDrivePath
    $HomeDriveChildPath
    $NewUser
    $NewUserCheck = Get-ADUser -Filter {Name -eq $NewUser} -SearchBase "OU=Users,DC=domain,DC=pl"

    if ($NewUserCheck) {
        $a = "$HomeDriveChildPath\$NewUser"
        $b = "DOMAIN\$NewUser"
        $ACL = Get-Acl $a
        $AR = New-Object System.Security.AccessControl.FileSystemAccessRule("$b", "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
        $ACL.SetAccessRule($AR)
                
        Set-Acl $a $ACL
    }

}

function Add-SharingToFolder {
    $ParentSuffix = [Math]::Floor($num / 100) * 100
    $HomeDriveFormat = "K{0:D4}" -f [int]$ParentSuffix
    $credentials

    Invoke-Command -ComputerName "vm01" -Credential $credentials -ScriptBlock {
        $c = "$($using:NewUser)$"
        $d = "H:\HOME\$($using:HomeDriveFormat)\$($using:NewUser)"
        New-SmbShare -Name "$c" -Path "$d" -ChangeAccess "Wszyscy"
    }   
}
