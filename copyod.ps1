Write-Host "这是一个通过复制文件快速塞满OneDrive 5TB的实例"
Write-Host "登陆账号请使用全局默认域名账号：XX@XXX.onmicrosoft.com"
Write-Host "-------------------------------------------------------"
Do { $User = (Read-Host "Microsoft Office365 UserName") } While ([String]::IsNullOrEmpty($($User).Trim())) 
Do { $Passwd = (Read-Host "Microsoft Office365 Password") } While ([String]::IsNullOrEmpty($($Passwd).Trim()))
$SecureString = ConvertTo-SecureString -AsPlainText "${Passwd}" -Force
$MySecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ${User},${SecureString}

$UserUnderscore = $User -replace "[^a-zA-Z0-9]", "_"
$UserORG = ($UserUnderscore -Split "_")[1]
$OneDriveSite = "https://{0}-my.sharepoint.com/personal/{1}" -f $UserORG, $UserUnderscore
$RootDirectory = "Documents/copyod/"
$FirstFolder = $RootDirectory + "FirstFolder/"

try {
	Write-Host "Login: ${User}" -ForegroundColor Green
	Connect-PnPOnline -Url $OneDriveSite -Credentials $MySecureCreds

	Write-Host "Upload File to $OneDriveSite"
	$FileName = -join ([char[]](65..90) | Get-Random -Count 4)
	$FileSize = Get-Random -Maximum 530 -Minimum 500
	dd if=/dev/zero of=$FileName bs=1M count=0 seek=$FileSize
	Add-PnPFile -Path $FileName -Folder $RootDirectory 2>&1>$null
	Remove-Item $FileName -Force
	Resolve-PnPFolder -SiteRelativePath $FirstFolder 2>&1>$null
	
	for($i=1;$i -le 100;$i++){
		Write-Progress -Activity "Copy files..." -Status "$i% Complete:" -PercentComplete $i
		$NewFileName = -join ([char[]](65..90) | Get-Random -Count 8)
		Copy-PnPFile -SourceUrl ${RootDirectory}${FileName} -TargetUrl ${FirstFolder}${NewFileName} -OverwriteIfAlreadyExists -Force -ErrorAction Stop
	}

	for($i=1;$i -le 100;$i++){
		Write-Progress -Activity "Copy folders..." -Status "$i% Complete:" -PercentComplete $i
		$NewFolderName = -join ([char[]](65..90) | Get-Random -Count 8)
		Copy-PnPFile -SourceUrl $FirstFolder -TargetUrl ${RootDirectory}${NewFolderName} -OverwriteIfAlreadyExists -Force -ErrorAction SilentlyContinue
	}

	Disconnect-PnPOnline
	Write-Host "Finish"
}

catch {
	Write-Host "Error: $_" -ForegroundColor Red
}

Finally {
	Pause
	Exit 1
	#clear
}
