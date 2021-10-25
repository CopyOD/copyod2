[CmdletBinding()]
Param([String]$u, [String]$p)

$CommandList = (Get-Command -All)
If (-Not ("Connect-PnPOnline" -in $CommandList.Name)) { Write-Host "`nInstall..."; Install-Module -Scope CurrentUser -Name PnP.PowerShell -Force }
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

	Write-Host "Upload File to $OneDriveSite"
	$FileName = -join ([char[]](65..90) | Get-Random -Count 4)
	$FileSize = Get-Random -Maximum 550 -Minimum 500
	dd if=/dev/zero of=$FileName bs=1M count=0 seek=$FileSize 2>&1>$null
	Add-PnPFile -Path $FileName -Folder "Documents" 2>&1>$null
	Remove-Item $FileName -Force

	Resolve-PnPFolder -SiteRelativePath "Documents/FirstFolder" 2>&1>$null
	for($i=1;$i -le 100;$i++){
		Write-Progress -Activity "Copy files..." -Status "$i% Complete:" -PercentComplete $i
		$NewFileName = -join ([char[]](65..90) | Get-Random -Count 8)
		Copy-PnPFile -SourceUrl ${RootDirectory}${FileName} -TargetUrl ${FirstFolder}${NewFileName} -OverwriteIfAlreadyExists -Force -ErrorAction Stop
		Start-Sleep -Seconds 1
	}

	for($i=1;$i -le 100;$i++){
		Write-Progress -Activity "Copy folders..." -Status "$i% Complete:" -PercentComplete $i
		$NewFolderName = -join ([char[]](65..90) | Get-Random -Count 8)
		Copy-PnPFile -SourceUrl $FirstFolder -TargetUrl ${RootDirectory}${NewFolderName} -OverwriteIfAlreadyExists -Force -ErrorAction SilentlyContinue
		Start-Sleep -Seconds 1
	}

	Disconnect-PnPOnline
}

catch {
	Write-Host "Error: $_" -ForegroundColor Red
}
