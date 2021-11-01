[CmdletBinding()]
Param([String]$u, [String]$p)
#Install-Module -Name PnP.PowerShell

#Function to Upload Large File to SharePoint Online Library
Function Upload-LargeFile($FilePath, $LibraryName, $FileChunkSize=10) {
	$Ctx = Get-PnPContext
    Try {
        #Get File Name
        $FileName = [System.IO.Path]::GetFileName($FilePath)
        $UploadId = [GUID]::NewGuid()

        #Get the folder to upload
        $Library = $Ctx.Web.Lists.GetByTitle($LibraryName)
        $Ctx.Load($Library)
        $Ctx.Load($Library.RootFolder)
        $Ctx.ExecuteQuery()

        $BlockSize = $FileChunkSize * 1024 * 1024
        $FileSize = (Get-Item $FilePath).length
        If($FileSize -le $BlockSize) {
            #Regular upload
            $FileStream = New-Object IO.FileStream($FilePath,[System.IO.FileMode]::Open)
            $FileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
            $FileCreationInfo.Overwrite = $true
            $FileCreationInfo.ContentStream = $FileStream
            $FileCreationInfo.URL = $FileName
            $Upload = $Docs.RootFolder.Files.Add($FileCreationInfo)
            $ctx.Load($Upload)
            $ctx.ExecuteQuery()
        }
        Else {
            #Large File Upload in Chunks
            $ServerRelativeUrlOfRootFolder = $Library.RootFolder.ServerRelativeUrl
            [Microsoft.SharePoint.Client.File]$Upload
            $BytesUploaded = $null
            $Filestream = $null
            $Filestream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $BinaryReader = New-Object System.IO.BinaryReader($Filestream)
            $Buffer = New-Object System.Byte[]($BlockSize)
            $LastBuffer = $null
            $Fileoffset = 0
            $TotalBytesRead = 0
            $BytesRead
            $First = $True
            $Last = $False

            #Read data from the file in blocks
			$ChunksAmount = [Math]::Ceiling($FileSize / $BlockSize); $i=0
            While(($BytesRead = $BinaryReader.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
				$i++; $PercentComplete = [Math]::Round($i/$ChunksAmount*100)
				Write-Progress -Activity "Upload File..." -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
				$TotalBytesRead = $TotalBytesRead + $BytesRead
                If ($TotalBytesRead -eq $FileSize) {
                    $Last = $True
                    $LastBuffer = New-Object System.Byte[]($BytesRead)
                    [Array]::Copy($Buffer, 0, $LastBuffer, 0, $BytesRead)
                }
                If($First) {
                    #Create the File in Target
                    $ContentStream = New-Object System.IO.MemoryStream
                    $FileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
                    $FileCreationInfo.ContentStream = $ContentStream
                    $FileCreationInfo.Url = $FileName
                    $FileCreationInfo.Overwrite = $true
                    $Upload = $Library.RootFolder.Files.Add($FileCreationInfo)
                    $Ctx.Load($Upload)
 
                    #Start FIle upload by uploading the first slice
                    $s = new-object System.IO.MemoryStream(, $Buffer)
                    $BytesUploaded = $Upload.StartUpload($UploadId, $s)
                    $Ctx.ExecuteQuery()
                    $fileoffset = $BytesUploaded.Value
                    $First = $False
                }
                Else {
                    #Get the File Reference
                    $Upload = $ctx.Web.GetFileByServerRelativeUrl($Library.RootFolder.ServerRelativeUrl + [System.IO.Path]::AltDirectorySeparatorChar + $FileName);
                    If($Last) {
                        $s = [System.IO.MemoryStream]::new($LastBuffer)
                        $Upload = $Upload.FinishUpload($UploadId, $fileoffset, $s)
                        $Ctx.ExecuteQuery()
                        Write-Host "File Upload completed!" -f Green
                    }
                    Else {
                        #Update fileoffset for the next slice
                        $s = [System.IO.MemoryStream]::new($buffer)
                        $BytesUploaded = $Upload.ContinueUpload($UploadId, $fileoffset, $s)
                        $Ctx.ExecuteQuery()
                        $fileoffset = $BytesUploaded.Value
                    }
                }
            }
        }
    }
    Catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    Finally {
        If($Filestream -ne $null)
        {
            $Filestream.Dispose()
        }
		Remove-Item $FilePath -Force
    }
}

#Copy OneDriveSite
function Copy-Files($FilePath) {
	Resolve-PnPFolder -SiteRelativePath $FirstFolder 2>&1>$null
	Try {
		Move-PnPFile -SourceUrl $FilePath -TargetUrl ${RootDirectory}${FileName} -Force
		for($i=1;$i -le 100;$i++){
			Write-Progress -Activity "Copy files..." -Status "$i% Complete:" -PercentComplete $i
			$NewFileName = -join ([char[]](65..90) | Get-Random -Count 8)
			Copy-PnPFile -SourceUrl ${RootDirectory}${FileName} -TargetUrl ${FirstFolder}${NewFileName} -OverwriteIfAlreadyExists -Force -ErrorAction Stop
		}
		Write-Host "File Copy completed!" -f Green
		for($i=1;$i -le 100;$i++){
			Write-Progress -Activity "Copy folders..." -Status "$i% Complete:" -PercentComplete $i
			$NewFolderName = -join ([char[]](65..90) | Get-Random -Count 8)
			Copy-PnPFile -SourceUrl $FirstFolder -TargetUrl ${RootDirectory}${NewFolderName} -OverwriteIfAlreadyExists -Force -ErrorAction SilentlyContinue
		}
		Write-Host "File folders completed!" -f Green
	}
    Catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

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
$UserUnderscore = $User -replace "[^a-zA-Z0-9]", "_"
$UserORG = ($UserUnderscore -Split "_")[1]
$OneDriveSite = "https://{0}-my.sharepoint.com/personal/{1}" -f $UserORG, $UserUnderscore
$RootDirectory = "Documents/copyod/"
$FirstFolder = $RootDirectory + "FirstFolder/"
Write-Host $OneDriveSite
Try {
	Write-Host "Login: ${User}" -ForegroundColor Green
	Try {
		Connect-PnPOnline -Url $OneDriveSite -Credentials $MySecureCreds
		$FileName = -join ([char[]](65..90) | Get-Random -Count 4)
		$FileSize = Get-Random -Maximum 531000000 -Minimum 530000000
		if ($IsWindows -or $ENV:OS) {
			fsutil file createnew $SplitPath/$FileName $FileSize 2>&1>$null
		} else {
			dd if=/dev/zero of=$SplitPath/$FileName bs=1 count=0 seek=$FileSize 2>&1>$null
		}
		Upload-LargeFile -FilePath "$SplitPath/$FileName" -LibraryName "Documents"
		Copy-Files -FilePath "Documents/$FileName"
		Write-Host "Finish!`n" -ForegroundColor Green
		Disconnect-PnPOnline
	}
	Catch {
		Write-Host $_.Exception.Message -ForegroundColor Red
	}
}
Catch {
	Write-Host $_.Exception.Message -ForegroundColor Red
}
Pause
