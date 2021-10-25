while($true){
	Write-Host "这是一个使用PowerShell复制OneDrive文件的实例测试"
	Do { $User = (Read-Host "Microsoft Office365 UserName") } While ([String]::IsNullOrEmpty($($User).Trim())) 
	Do { $Passwd = (Read-Host "Microsoft Office365 Password") } While ([String]::IsNullOrEmpty($($Passwd).Trim()))
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
		Pause
		Clear-Host
	}
}
