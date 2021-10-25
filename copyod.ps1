[CmdletBinding()]
Param([String]$u, [String]$p)

If ([String]::IsNullOrEmpty($($u).Trim())) { 
  Do { $User = (Read-Host "Microsoft Office365 UserName") } While ([String]::IsNullOrEmpty($($User).Trim())) 
} Else {
  $User = $u
}
If ([String]::IsNullOrEmpty($($p).Trim())) { 
  Do { $Passwd = (Read-Host "Microsoft Office365 Password") } While ([String]::IsNullOrEmpty($($Passwd).Trim()))
} Else {
  $Passwd = $p
}
$SecureString = ConvertTo-SecureString -AsPlainText "${Passwd}" -Force
$MySecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ${User},${SecureString}


$UserUnderscore = $User -replace "[^a-zA-Z]", "_"
$UserORG = ($UserUnderscore -Split "_")[1]
$RootDirectory = "/personal/$UserUnderscore/Documents/"
$FirstFolder = "/personal/$UserUnderscore/Documents/FirstFolder/"
$OneDriveSite = "https://$UserORG-my.sharepoint.com/personal/$UserUnderscore"

try {
	Write-Host "Login: ${User}" -ForegroundColor Green
	Connect-PnPOnline -Url $OneDriveSite -Credentials $MySecureCreds
	If (-Not $?) { Write-Host "Error: PnPOnline Authentication." -ForegroundColor red; Exit 1; }


	Disconnect-PnPOnline
}

catch {
	Write-Host "Error: $_" -ForegroundColor Red
}

Finally {
    exit
}
