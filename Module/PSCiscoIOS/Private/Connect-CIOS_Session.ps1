<# 
 .SYNOPSIS 
 Connects to switchSession Switch 

.DESCRIPTION 
 Uses Sockets to Connects to switchSession Switch 

.PARAMETER switchsession 
 string Parameter_switchsession=The switchSession object that is trying to connect 

.NOTES 
  

#> 
function Connect-CIOS_Session () {
 
	param(
		[Parameter(mandatory = $true)] $switchsession
	)

	if ($switchsession.socket.Connected) {
		if (($switchsession.cred -ne ([pscredential]::Empty))) {
			$username = $switchsession.cred.username
			$password = $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($($switchsession.cred.Password))))
			$switch = $switchsession.hostname
			if ($switchsession.encred) {
				$en = $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($($switchsession.encred.Password))))
			} else { $en = "null" }
			$Port = $switchsession.port
			$WaitTime = $switchsession.WaitTime

			Write-Progress -Activity "Connecting to Switch" -PercentComplete 0
			#Attach to switch
			if ($switchSession.socket)
			{
				Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "stream" -Value ($switchSession.socket.GetStream()) -Force
				Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "writer" -Value (New-Object System.IO.StreamWriter ($switchSession.Stream)) -Force
				Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "buffer" -Value (New-Object System.Byte[] 1024) -Force
				Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "encoding" -Value (New-Object System.Text.AsciiEncoding) -Force

				Write-Progress -Activity "Entering Username" -PercentComplete 25
				#enter Username
				do
				{
					$Read = $switchSession.Stream.Read($switchSession.Buffer,0,1024)
					$lineRead = ($switchSession.Encoding.GetString($switchSession.Buffer,0,$Read))
					Write-Verbose $($lineread)
					Start-Sleep -Milliseconds $WaitTime
				} while ($lineRead -notlike "*Username:*")
				$switchSession.Writer.WriteLine($username)
				$switchSession.Writer.Flush()

				Write-Progress -Activity "Entering Password" -PercentComplete 50
				#enter Password
				do
				{
					$Read = $switchSession.Stream.Read($switchSession.Buffer,0,1024)
					$lineRead = ($switchSession.Encoding.GetString($switchSession.Buffer,0,$Read))
					Write-Verbose $($lineread)
					Start-Sleep -Milliseconds $WaitTime
				} while ($lineRead -notlike "*Password:*")
				$switchSession.Writer.WriteLine($password)
				$switchSession.Writer.Flush()

				Write-Progress -Activity "Waiting for CommandPrompt" -PercentComplete 75
				#wait for first command prompt
				$switchname = (Invoke-CIOS_WaitForPrompt -returnLine -switchsession $switchSession -break "Authentication failed").split("`n")[2].split(">")[0]
				Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "SwitchName" -Value ($switchname)

				Invoke-CIOS_FullTermLength -switchsession $switchSession

				#enter enable
				if ($en -ne "null")
				{
					Write-Progress -Activity "Entering Enable Mode" -PercentComplete 90
					$switchSession.Writer.WriteLine("en")
					$switchSession.Writer.Flush()
					do
					{
						$Read = $switchSession.Stream.Read($switchSession.Buffer,0,1024)
						$lineRead = ($switchSession.Encoding.GetString($switchSession.Buffer,0,$Read))
						Write-Verbose $($lineread)
						Start-Sleep -Milliseconds $WaitTime
					} while ($lineRead -notlike "*Password:*")
					$switchSession.Writer.WriteLine($en)
					$switchSession.Writer.Flush()
					Invoke-CIOS_WaitForPrompt -switchsession $switchSession -break "Access denied" -returnError "EnableMode: Access denied"
					Invoke-CIOS_FullTermLength -switchsession $switchSession
					Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "EN" -Value $true
				}
				else {
					Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "EN" -Value $false
				}


			}
			else
			{
				Write-Progress -Activity "ERROR" -Completed
				throw [System.IO.FileNotFoundException]"Unable to connect to switch: $($switch):$Port"
				return "Unable to connect to switch: $($switch):$Port"
			}
			$switchsession.Authenticated = $true
			Write-Progress -Activity "Connection Established" -Completed
		}
		else {
			throw [System.Exception]"Please set Credential first `".Credentials()`""
		}
	} else {
		throw [System.Exception]"Socket Closed Communication with switch has been halted; object will be recreated"
		$Thostname = $switchsession.hostname
		$TPort = $switchsession.port
		$TWaitTime = $switchsession.WaitTime
		$Tcred = $switchsession.cred
		$Tencred = $switchsession.encred
		$switchsession.Dispose()
		$switchsession = New-CIOS_Session -hostname $Thostname -Port $TPort -WaitTime $TWaitTime
		$switchsession.cred = $tcred
		$switchsession.encred = $tencred
	}

}
