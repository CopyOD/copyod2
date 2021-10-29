Write-Host "这是一个通过复制文件快速塞满OneDrive 5TB的实例"
Write-Host "登陆全局默认域管理员账号：XX@XXX.onmicrosoft.com"
Write-Host "-------------------------------------------------------"
Do { $AdminUser = (Read-Host "Microsoft Office365 AdminUser") } While ([String]::IsNullOrEmpty($($AdminUser).Trim())) 
Do { $AdminPwd = (Read-Host "Microsoft Office365 AdminPwd") } While ([String]::IsNullOrEmpty($($AdminPwd).Trim()))
$SecureString = ConvertTo-SecureString -AsPlainText "${AdminPwd}" -Force
$MySecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ${AdminUser},${SecureString}

try {
	az login -u $AdminUser -p $AdminPwd --allow-no-subscriptions --only-show-errors 
	$PnPPowerShellAppId = "31359c7f-bd7e-475c-86db-fdb8c937548e"
	$existUAPI = az ad sp show --id $PnPPowerShellAppId 
	If ([String]::IsNullOrEmpty($existUAPI)) { 
		az ad sp create --id $PnPPowerShellAppId 
		az ad app permission grant --id $PnPPowerShellAppId --api 00000003-0000-0000-c000-000000000000 --scope User.Read.All,Group.ReadWrite.All 
		az ad app permission grant --id $PnPPowerShellAppId --api 00000003-0000-0ff1-ce00-000000000000 --scope User.Read.All,Sites.FullControl.All 
	}
	
	$UserORG = ($AdminUser -Split {$_ -eq "@" -or $_ -eq "."})[1]
	$OneDriveSite = "https://{0}-my.sharepoint.com/personal/xs_{0}_onmicrosoft_com" -f $UserORG
	$RootDirectory = "Documents/copyod/"
	$FirstFolder = $RootDirectory + "FirstFolder/"
	Connect-PnPOnline -Url $OneDriveSite -Credentials $MySecureCreds
	Set-PnPTenantSite -Identity $OneDriveSite -Owners $AdminUser
	
	Write-Host "Upload File to $OneDriveSite"
	$FileName = -join ([char[]](65..90) | Get-Random -Count 4)
	$FileSize = Get-Random -Maximum 530 -Minimum 500
	dd if=/dev/zero of=$FileName bs=1M count=0 seek=$FileSize 
	Add-PnPFile -Path $FileName -Folder $RootDirectory 
	Remove-Item $FileName -Force
	Resolve-PnPFolder -SiteRelativePath $FirstFolder 
	
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
	
	$GetSPO = Get-PnPTenantSite -Url $OneDriveSite
	$UsageAmount = [math]::Round($GetSPO.StorageUsageCurrent / $GetSPO.StorageQuota * 100,2)
	Write-Host "User: $($GetSPO.Owner), StorageQuota: $($($GetSPO.StorageQuota) / 1024 / 1024)TB, UsageAmount：$UsageAmount%" -ForegroundColor Green
	Remove-PnPSiteCollectionAdmin -Owners $AdminUser
	
	az account clear
	Disconnect-PnPOnline
}
catch {
	Write-Host "Error: $_" -ForegroundColor Red
}
Finally {
	Pause
	Exit 1
}
