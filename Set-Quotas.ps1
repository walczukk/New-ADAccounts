Import-Module ActiveDirectory

function Set-Quotas {
    param (
        [string]$HomeDriveFormat,
        [string]$TargetFS,
        [pscredential]$credentials
    )
} Try {
    Invoke-Command -ComputerName $TargetFS -Credential $credentials -ScriptBlock {
        param (
        $HomeDriveFormat
    )
        $CheckQuota = Get-FSRMAutoQuota -Path "H:\HOME\$HomeDriveFormat"
        if ($CheckQuota.Template -eq "Quota limit for HOME") {

        } else {
            New-FsrmAutoQuota -Path "H:\HOME\$HomeDriveFormat" -Template "Quota limit for HOME"
        }
    } -ArgumentList $HomeDriveFormat, $NewUser, $TargetFS
} Catch {
    Write-Host "BŁĄD $($_.Exception.Message)" -BackgroundColor Red
}
