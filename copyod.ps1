Write-Host "这是一个使用PowerShell复制OneDrive文件的实例测试"
Write-Host "登陆账号请使用全局默认域名账号：XX@XXX.onmicrosoft.com"
Write-Host "https://login.microsoftonline.com/organizations/v2.0/adminconsent?client_id=31359c7f-bd7e-475c-86db-fdb8c937548e&scope=https://graph.microsoft.com/AppCatalog.ReadWrite.All"
Write-Host "-------------------------------------------------------"
Do { $User = (Read-Host "Microsoft Office365 UserName") } While ([String]::IsNullOrEmpty($($User).Trim())) 
Do { $Passwd = (Read-Host "Microsoft Office365 Password") } While ([String]::IsNullOrEmpty($($Passwd).Trim()))
$SecureString = ConvertTo-SecureString -AsPlainText "${Passwd}" -Force
$MySecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ${User},${SecureString}

$UserUnderscore = $User -replace "[^a-zA-Z]", "_"
$UserORG = ($UserUnderscore -Split "_")[1]
$OneDriveSite = "https://$UserORG-my.sharepoint.com/personal/$UserUnderscore"
$RootDirectory = "Documents/copyod/"
$FirstFolder = $RootDirectory + "FirstFolder/"

try {
	Write-Host "Login: ${User}" -ForegroundColor Green
	Connect-PnPOnline -Url $OneDriveSite -Credentials $MySecureCreds
	Write-Host "Upload File to $OneDriveSite"
	$FileName = -join ([char[]](65..90) | Get-Random -Count 4)
	$FileSize = Get-Random -Maximum 550 -Minimum 500
	dd if=/dev/zero of=$FileName bs=1M count=0 seek=$FileSize 2>&1>$null
	Add-PnPFile -Path $FileName -Folder $RootDirectory 2>&1>$null
	Remove-Item $FileName -Force

	Resolve-PnPFolder -SiteRelativePath $FirstFolder 2>&1>$null
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
Finally {
	Pause
	Exit 1
}
