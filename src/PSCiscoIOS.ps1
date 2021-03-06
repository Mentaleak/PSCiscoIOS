<# 
.SYNOPSIS 
Waits for a propmpt symbol in the line feed

.DESCRIPTION 
Waits for a propmpt symbol in the line feed, used when waiting for the switch to finish spitting out data before entering new data

.PARAMETER switchSession
switchSession is a session object that has the details of an open session that you would like to wait for

.PARAMETER break
string, is a line to watch for that would indicate the previously entered command failed

.PARAMETER returnerror
string, error message to be displayed if the previously entered command failed (default is same as break message)

.PARAMETER returnLine
switch, if on returns line read

.NOTES 
 Author: Mentaleak 

#>
function Invoke-CIOS_WaitForPrompt () {
	param(
		[Parameter(mandatory = $true)] $switchSession,
		[string]$break,
		[string]$returnError = $break,
		[switch]$returnLine
	)
	do
	{
		$Read = $switchSession.Stream.Read($switchSession.Buffer,0,1024)
		$lineRead = ($switchSession.Encoding.GetString($switchSession.Buffer,0,$Read))
		Write-Verbose $($lineread)
		if ($lineRead -like "*$break*")
		{
			Write-Progress -Activity "ERROR" -Completed
			throw [System.IO.FileNotFoundException]"$returnError"
			return "$returnError" }
		Start-Sleep -Milliseconds $WaitTime
	} while (!($lineRead -notlike "*>*" -xor $lineRead -notlike "*#*"))
	if ($returnLine) { return $lineRead }
}

<# 
.SYNOPSIS 
Extends Terminal length

.DESCRIPTION 
Extends Terminal length so that there isn't need for input to scroll

.PARAMETER switchSession
switchSession is a session object that has the details of an open session that you would like to wait for

.NOTES 
 Author: Mentaleak 

#>
function Invoke-CIOS_FullTermLength () {
	param(
		[Parameter(mandatory = $true)] $switchSession
	)
	if ($switchsession.socket.Connected) {
		$command = "terminal length 0"
		Write-Progress -Activity "Processing command $Command" -PercentComplete 50
		$switchSession.Writer.WriteLine($command)
		$switchSession.Writer.Flush()
		do
		{
			$Read = $switchSession.Stream.Read($switchSession.Buffer,0,1024)
			$lineRead = ($switchSession.Encoding.GetString($switchSession.Buffer,0,$Read))
			Write-Verbose $($lineread)
			if ($lineRead -like "*Invalid input detected*")
			{
				Write-Progress -Activity "ERROR" -Completed
				throw [System.IO.FileNotFoundException]"$($command): Invalid input detected"
				return "$($command): Invalid input detected" }
			Start-Sleep -Milliseconds $WaitTime
		} while (!($lineRead -notlike "*>*" -xor $lineRead -notlike "*#*"))
	}
	else
	{
		Write-Progress -Activity "ERROR" -Completed
		throw [System.IO.FileNotFoundException]"$($switchSession.SwitchName) Connection is not connected"
		return "$($switchSession.SwitchName) Connection is not connected"
	}
	$switchSession.Writer.Flush()
}

<# 
.SYNOPSIS 
Creates new CISCO IOS Credentials

.DESCRIPTION 
Creates new CISCO IOS Credentials for the given hostname or will make a default one if no switchname is present
Will use better credentials stored github Credentials "CiscoIOS_<hostname>_login" and "CiscoIOS_<hostname>_en" if they exist in local keystore

.PARAMETER SwitchHostname
String will be hostname of switch credential is for if not using default

.Example
new-switchCredential
Makes new default switch Credential

.NOTES 
 Author: Mentaleak 

#>
function new-CIOS_Credential () {
	param(
		[string]$SwitchHostname,
		[switch]$en
	)
	if ($switchHostname -or !($SwitchHostname -eq "")) {
		$credentialTarget = "CiscoIOS_$($SwitchHostname)"
	} else {
		$credentialTarget = "CiscoIOS"
	}
	#login
	if (!($en)) {
		$bcred = (Get-Credential -Title "Cisco IOS Login" -Description "Enter Cisco IOS login Credentials")
		if ($bcred) { Set-Credential -Credential $bcred -Target "$($credentialTarget)_login" -Description "Cisco IOS login Credential" }


	}
	#EN
	else {
		$bcred = (Get-Credential -Title "Cisco IOS EN" -Description "Enter Cisco IOS EN Credentials")
		if ($bcred) { Set-Credential -Credential $bcred -Target "$($credentialTarget)_EN" -Description "Cisco IOS login Credential" }

	}
}

<# 
.SYNOPSIS 
Sets CISCO IOS Credentials for SwitchSession

.DESCRIPTION 
Sets CISCO IOS Credentials for SwitchSession, based on what is in credential store or prompts user for credentials

.PARAMETER SwitchSession
The CIOS object to work on

.PARAMETER masterCreds
bool, use master creds?

.NOTES 
 CIOS SwitchSession Method
 Author: Mentaleak 


#>
function set-CIOS_Session-Credential () {
	param(
		[Parameter(mandatory = $true)] $switchsession,
		[bool]$masterCreds
	)
	if (!($masterCreds)) {
		$switchHostname = $switchsession.hostname
	}
	if ($switchHostname -or $SwitchHostname -eq "") {
		$credentialTarget = "CiscoIOS_$($SwitchHostname)"
	} else {
		$credentialTarget = "CiscoIOS"
	}


	try {
		$cred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_login")[0])
	}
	catch {
		new-CIOS_Credential $SwitchHostname
		try {
			$cred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_login")[0])
		} catch {}
	}



	$switchsession.cred = $cred




	try {
		$encred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_EN")[0])
	}
	catch {
		$idk = [System.Windows.Forms.MessageBox]::Show("Do You know the en creds"," Question?","YesNo")
		if ($idk -eq "Yes") {
			new-CIOS_Credential -en $SwitchHostname
			try {
				$encred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_EN")[0])
			} catch {}
		}
	}

	$switchsession.encred = $encred





}

<# 
.SYNOPSIS 
Creates a new CIOS Session

.DESCRIPTION 
Instantiates a new CIOS Session object

.PARAMETER hostname
[String] hostname or IP of the switch

.PARAMETER port
[string] Port to connect to, default 23

.PARAMETER WaitTime
[int] time to wait between line reads

.Example
$switchSession= New-CIOS_Session -hostname "testswitch.domain.local"

.NOTES 
 Author: Mentaleak 

#>
function New-CIOS_Session () {
	param(
		[Parameter(mandatory = $true)] [string]$hostname,
		[string]$Port = "23",
		[int]$WaitTime = 100
	)
	$switchSession = New-Object PSObject
	$typename = 'CIOS.Switch.Session'
	$switchSession.PSObject.TypeNames.Insert(0,$typename)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Hostname" -Value ($hostname)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Port" -Value ($Port)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "WaitTime" -Value ($WaitTime)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Socket" -Value (New-Object System.Net.Sockets.TcpClient ($hostname,$Port))
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Cred" -Value ([pscredential]::Empty)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Encred" -Value ([pscredential]::Empty)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Authenticated" -Value $false
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "UpdateTimes" -Value (New-Object -TypeName psobject)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "IntStatus_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "MacTable_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Version_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Config_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "CommandLog" -Value @()
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "CIOSLog" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "CommandLogRaw" -Value @()

	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "Dispose" -Value {
		remove-object_Pstool -InputObject $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "Credentials" -Value {
		param([bool]$masterCredentials)
		set-CIOS_Session-Credential -switchsession $this -masterCreds $masterCredentials
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "Connect" -Value {
		Connect-CIOS_Session -switchsession $this
	} -Force

	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getIntStatus" -Value {
		get-CIOS_IntStatus -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getMacTable" -Value {
		get-CIOS_MacTable -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getConfig" -Value {
		get-CIOS_Config -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getVersion" -Value {
		get-CIOS_Version -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getDATA" -Value {
		get-CIOS_IntStatus -switchsession $this
		get-CIOS_MacTable -switchsession $this
		get-CIOS_Config -switchsession $this
		get-CIOS_Version -switchsession $this
		foreach ($port in $this.IntStatus_Latest.port) {
			$this.getIntInfo($port)
		}
		get-CIOS_log -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getIntInfo" -Value {
		param([Parameter(mandatory = $true)] [string]$interface)
		get-CIOS_IntInfo -switchsession $this -interface $interface
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "RunCommand" -Value {
		param([Parameter(mandatory = $true)] [string]$command,
			[bool]$writeresult)
		Invoke-CIOS_Command -switchsession $this -Command $command -writeresult $writeresult
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getCIOSLog" -Value {
		get-CIOS_log -switchsession $this
	} -Force


	#$switchsession.Credentials()
	return $switchSession
}

<# 
.SYNOPSIS 
Connects to switchSession Switch

.DESCRIPTION 
Uses Sockets to Connects to switchSession Switch

.PARAMETER switchsession
The switchSession object that is trying to connect

.NOTES 
 Author: Mentaleak

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

<# 
.SYNOPSIS 
Gets the interface Status from the switch

.DESCRIPTION 
Gets the interface Status from the switch (Show interface Status)
Sets the data parsed into an array of custom objects into IntStatus_Latest
Sets the time into UpdateTimes

.PARAMETER switchsession
The switchSession object that you're getting data for

.NOTES 
 Author: Mentaleak

#>
function get-CIOS_IntStatus () {
	param(
		[Parameter(mandatory = $true)] $switchSession
	)
	if ($switchsession.socket.Connected -and $switchSession.Authenticated) {
		$waittime = $switchSession.WaitTime
		$commandResult = Invoke-CIOS_Command -switchsession $switchSession -Command "sh int status"
		$portArray = @()
		$linenumber = 2
		do
		{
			$portdata = New-Object -TypeName psobject -Property @{
				port = "$($commandresult[$linenumber].Substring(0,10).trim())"
				Name = "$($commandresult[$linenumber].Substring(10,18).trim())"
				Status = "$($commandresult[$linenumber].Substring(28,13).trim())"
				Vlan = "$($commandresult[$linenumber].Substring(41,11).trim())"
				Duplex = "$($commandresult[$linenumber].Substring(52,8).trim())"
				Speed = "$($commandresult[$linenumber].Substring(60,6).trim())"
				Type = "$($commandresult[$linenumber].Substring(66,($commandresult[$linenumber].length-66)).trim())"
				Parent = $switchSession
			}
			Add-Member -MemberType ScriptMethod -InputObject $portdata -Name "getIntInfo" -Value {
				get-CIOS_IntInfo -switchsession $this.Parent -interface "$($this.port)"
			} -Force
			Add-Member -MemberType ScriptMethod -InputObject $portdata -Name "resetInterface" -Value {
				reset-CIOS_Interface -switchsession $this.Parent -interface "$($this.port)"
			} -Force

			# $portdata.psobject.members.Remove("Parent")

			$typename = 'CIOS.interface.status'
			$portdata.PSObject.TypeNames.Insert(0,$typename)

			$portArray += $portdata
			$linenumber++
		} while ($commandresult[$linenumber].Length -gt 0)

		$defaultDisplaySet = 'Port','Name','Status','Vlan','Duplex','Speed','Type'
		set-Psobject_formatTable_Pstool -InputObject $portdata -Columns $defaultDisplaySet
		$switchSession.IntStatus_Latest = $portArray

		Add-Member -InputObject ($switchSession.UpdateTimes) -MemberType NoteProperty -Name "IntStatus" -Value (Get-Date) -Force
		# $portArray | Format-Table
	}
	else {
		throw [System.Exception]"Please connect first `".Connect()`""
	}
}

<# 
.SYNOPSIS 
Gets the mac address table

.DESCRIPTION 
Gets the Mac Table from the switch (show mac address-table)
Sets the data parsed into an array of custom objects into MacTable_Latest
Sets the time into UpdateTimes

.PARAMETER switchsession
The switchSession object that you're getting data for

.NOTES 
 Author: Mentaleak

#>
function get-CIOS_MacTable () {
	param(
		[Parameter(mandatory = $true)] $switchSession
	)
	if ($switchsession.socket.Connected -and $switchSession.Authenticated) {
		$commandResult = Invoke-CIOS_Command -switchsession $switchSession -Command "sh mac address-table"
		$MacArray = @()
		$linenumber = 5
		do
		{
			$MACdata = New-Object -TypeName psobject -Property @{
				Vlan = "$($commandresult[$linenumber].Substring(0,8).trim())"
				MAC = "$($commandresult[$linenumber].Substring(8,18).trim())"
				Type = "$($commandresult[$linenumber].Substring(26,12).trim())"
				port = "$($commandresult[$linenumber].Substring(38,($commandresult[$linenumber].length-38)).trim())"
			}
			$typename = 'CIOS.Mac.Data'
			$Macdata.PSObject.TypeNames.Insert(0,$typename)


			$MACArray += $Macdata
			$linenumber++
		} while (!($commandresult[$linenumber].Contains("Total Mac Addresses for this criterion:")))
		#>
		$defaultDisplaySet = 'MAC','VLAN','Port','Type'
		set-Psobject_formatTable_Pstool -InputObject $Macdata -Columns $defaultDisplaySet
		$switchSession.mactable_Latest = $MacArray
		Add-Member -InputObject ($switchSession.UpdateTimes) -MemberType NoteProperty -Name "MacTable" -Value (Get-Date) -Force
		# $MacArray |format-table
	}
	else {
		throw [System.Exception]"Please connect first `".Connect()`""
	}
}

<# 
.SYNOPSIS 
Gets the version information

.DESCRIPTION 
Gets the version data from the switch (show version)
Sets the data parsed into a custom object Version_Latest
Sets the time into UpdateTimes

.PARAMETER switchsession
The switchSession object that you're getting data for

.NOTES 
 Author: Mentaleak

#>
function get-CIOS_Version () {
	param(
		[Parameter(mandatory = $true)] $switchSession
	)
	if ($switchsession.socket.Connected -and $switchSession.Authenticated) {
		$commandResult = Invoke-CIOS_Command -switchsession $switchSession -Command "sh version"

		$SwitchVersion = New-Object -TypeName psobject -Property @{
			Uptime = ($commandResult | Where-Object { $_ -like "*uptime*" }).substring(($commandResult | Where-Object { $_ -like "*uptime*" }).IndexOf("is") + 2,($commandResult | Where-Object { $_ -like "*uptime*" }).Length - ($commandResult | Where-Object { $_ -like "*uptime*" }).IndexOf("is") - 2).trim()
			Last_restart = ($commandResult | Where-Object { $_ -like "*restarted*" }).substring(($commandResult | Where-Object { $_ -like "*restarted*" }).IndexOf("at") + 2,($commandResult | Where-Object { $_ -like "*restarted*" }).Length - ($commandResult | Where-Object { $_ -like "*restarted*" }).IndexOf("at") - 2).trim()
			System_Image = ($commandResult | Where-Object { $_ -like "*System image file*" }).substring(($commandResult | Where-Object { $_ -like "*System image file*" }).IndexOf("is") + 2,($commandResult | Where-Object { $_ -like "*System image file*" }).Length - ($commandResult | Where-Object { $_ -like "*System image file*" }).IndexOf("is") - 2).trim()
			Base_ethernet_MAC_Address = ($commandResult | Where-Object { $_ -like "Base ethernet MAC Address       :*" }).substring(34,($commandResult | Where-Object { $_ -like "Base ethernet MAC Address       :*" }).Length - 34).trim()
			Motherboard_assembly_number = ($commandResult | Where-Object { $_ -like "Motherboard assembly number     :*" }).split(":")[1].trim()
			Power_supply_part_number = ($commandResult | Where-Object { $_ -like "Power supply part number        :*" }).split(":")[1].trim()
			Motherboard_serial_number = ($commandResult | Where-Object { $_ -like "Motherboard serial number       :*" }).split(":")[1].trim()
			Power_supply_serial_number = ($commandResult | Where-Object { $_ -like "Power supply serial number      :*" }).split(":")[1].trim()
			Model_revision_number = ($commandResult | Where-Object { $_ -like "Model revision number           :*" }).split(":")[1].trim()
			Motherboard_revision_number = ($commandResult | Where-Object { $_ -like "Motherboard revision number     :*" }).split(":")[1].trim()
			Model_number = ($commandResult | Where-Object { $_ -like "Model number                    :*" }).split(":")[1].trim()
			System_serial_number = ($commandResult | Where-Object { $_ -like "System serial number            :*" }).split(":")[1].trim()
			Top_Assembly_Part_Number = ($commandResult | Where-Object { $_ -like "Top Assembly Part Number        :*" }).split(":")[1].trim()
			Top_Assembly_Revision_Number = ($commandResult | Where-Object { $_ -like "Top Assembly Revision Number    :*" }).split(":")[1].trim()
			Version_ID = ($commandResult | Where-Object { $_ -like "Version ID                      :*" }).split(":")[1].trim()
			CLEI_Code_Number = ($commandResult | Where-Object { $_ -like "CLEI Code Number                :*" }).split(":")[1].trim()
			Hardware_Board_Revision_Number = ($commandResult | Where-Object { $_ -like "Hardware Board Revision Number  :*" }).split(":")[1].trim()
			Ports = $commandResult[$commandResult.Length - 5].substring(7,6).trim()
			SW_Version = $commandResult[$commandResult.Length - 5].substring(32,22).trim()
			SW_Image = $commandResult[$commandResult.Length - 5].substring(54,$commandResult[$commandResult.Length - 5].Length - 54).trim()
			RAW = "$commandResult"
		}
		$typename = 'CIOS.Version.Data'
		$SwitchVersion.PSObject.TypeNames.Insert(0,$typename)
		$switchSession.Version_Latest = $SwitchVersion
		Add-Member -InputObject ($switchSession.UpdateTimes) -MemberType NoteProperty -Name "Version" -Value (Get-Date) -Force
	} else {
		throw [System.Exception]"Please connect first `".Connect()`""
	}
}

<# 
.SYNOPSIS 
Gets the device Config

.DESCRIPTION 
Gets the iconfiguration from the switch (show config)
Sets the data into config_Latest
Sets the time into UpdateTimes

.PARAMETER switchsession
The switchSession object that you're getting data for

.NOTES 
 Author: Mentaleak

#>
function get-CIOS_Config () {
	param(
		[Parameter(mandatory = $true)] $switchSession
	)
	if ($switchSession.EN -and ($switchsession.socket.Connected -and $switchSession.Authenticated)) {
		$commandResult = Invoke-CIOS_Command -switchsession $switchSession -Command "sh config"

		$switchSession.Config_Latest = $commandResult
		Add-Member -InputObject ($switchSession.UpdateTimes) -MemberType NoteProperty -Name "Config" -Value (Get-Date) -Force
	}
	else
	{
		$returnError = "EnableMode is Required"
		throw [System.Exception]"$returnError"
	}

}

<# 
.SYNOPSIS 
Invokes a command via the switch Session

.DESCRIPTION 
Runs a command string against the switch
Adds command to CommandLog
Returns a string array

.PARAMETER switchsession
The switchSession object that you're getting data for

.PARAMETER command
[string] the command you want to run against the switch

.PARAMETER writeResult
[bool] if True, writes result to host

.NOTES 
 Author: Mentaleak

#>
function Invoke-CIOS_Command () {
	param(
		[Parameter(mandatory = $true)] $switchSession,
		[Parameter(mandatory = $true)] [string]$command,
		[bool]$writeResult
	)
	if ($switchsession.socket.Connected -and $switchSession.Authenticated) {
		$switchSession.Writer.Flush()
		$waittime = $switchSession.WaitTime
		Write-Progress -Activity "Processing command $Command" -PercentComplete 50
		$commandoutput = ""
		$switchSession.Writer.WriteLine($command)
		$switchSession.Writer.Flush()
		do
		{
			$Read = $switchSession.Stream.Read($switchSession.Buffer,0,1024)
			$lineRead = ($switchSession.Encoding.GetString($switchSession.Buffer,0,$Read))
			$switchsession.CommandLogRaw += $lineRead
			Write-Verbose $($lineread)
			$commandoutput += $lineRead
			if ($lineRead -like "*Invalid input detected*")
			{
				Write-Progress -Activity "ERROR" -Completed
				throw [System.IO.FileNotFoundException]"$($command): Invalid input detected (May require EN)"
				return "$($command): Invalid input detected (May require EN)" }
			Start-Sleep -Milliseconds $WaitTime
		} while (!($lineRead -notlike "*$($switchSession.switchname)>*" -xor $lineRead -notlike "*$($switchSession.switchname)#*" -xor $lineRead -notlike "*$($switchSession.switchname)(config)#*" -xor $lineRead -notlike "*$($switchSession.switchname)(config-if)#*"))
		$CommandResult = $($commandoutput.split("`n")[1..($($commandoutput.split("`n").Length) - 2)])
		$commandObject = [pscustomobject]@{
			Command = $command
			Time = (Get-Date)
			Result = $commandResult
		}
		$typename = 'CIOS.Command.Data'
		$commandObject.PSObject.TypeNames.Insert(0,$typename)
		$switchsession.CommandLog += $commandObject
		if ($writeResult) { $CommandResult }
		return $CommandResult
	}
	else
	{
		Write-Progress -Activity "ERROR" -Completed
		throw [System.Exception]"$($switchSession.SwitchName) Connection is not connected"
		return "$($switchSession.SwitchName) Connection is not connected"
	}
	$switchSession.Writer.Flush()
}

<# 
.SYNOPSIS 
Gets the interface information from the switch

.DESCRIPTION 
Gets the interface Status from the switch (Show interface <INTID>)
Sets the data parsed into the portinfo field of the objects in IntStatus_Latest

.PARAMETER switchsession
The switchSession object that you're getting data for

.PARAMETER interface
[string] the name of the interface you would like to look at

.NOTES 
 Author: Mentaleak

#>
function get-CIOS_IntInfo () {
	param(
		[Parameter(mandatory = $true)] $switchSession,
		[Parameter(mandatory = $true)] [string]$interface
	)
	if ($switchsession.socket.Connected -and $switchSession.Authenticated) {
		if ($switchSession.IntStatus_Latest) {
			$waittime = $switchSession.WaitTime
			$commandResult = Invoke-CIOS_Command -switchsession $switchSession -Command "sh int $interface"
			if ($commandResult[2] -match "Description") {
				$portinfo = New-Object -TypeName psobject -Property @{
					PortType = "$($commandResult[1].split([string[]]@("Hardware is "), [System.StringSplitOptions]::RemoveEmptyEntries).split(",")[1].trim())"
					MAC = "$($commandResult[1].split([string[]]@("Hardware is "), [System.StringSplitOptions]::RemoveEmptyEntries).split(",")[2].split(" ")[3].trim())"
					Description = "$($commandResult[2].split(":")[1].trim())"
					RAWInfo = $commandresult
				}
			} else {

				$portinfo = New-Object -TypeName psobject -Property @{
					PortType = "$($commandResult[1].split([string[]]@("Hardware is "), [System.StringSplitOptions]::RemoveEmptyEntries).split(",")[1].trim())"
					MAC = "$($commandResult[1].split([string[]]@("Hardware is "), [System.StringSplitOptions]::RemoveEmptyEntries).split(",")[2].split(" ")[3].trim())"
					Description = "N/A"
					RAWInfo = $commandresult
				} }
			$typename = 'CIOS.interface.info'
			$portinfo.PSObject.TypeNames.Insert(0,$typename)
			$portdata = $switchSession.IntStatus_Latest | Where-Object { $_.port -eq "$interface" }
			if ($portdata -ne $null) {
				Add-Member -InputObject $portdata -MemberType NoteProperty -Name "PortInfo" -Value $portinfo -Force
			}
			else {
				throw [System.Exception]"Invalid Port"
			}
		} else {
			throw [System.Exception]"Please get int status first"
		}
	}
	else {
		throw [System.Exception]"Please connect first `".Connect()`""
	}
}

<# 
.SYNOPSIS 
Gets the log for the CIOS switch

.DESCRIPTION 
Gets the logs from the switch (Show log)
Sets the data parsed into the CIOSLog field of the switchsession

.PARAMETER switchsession
The switchSession object that you're getting data for

.NOTES 
 Author: Mentaleak

#>
function get-CIOS_log () {
	param(
		[Parameter(mandatory = $true)] $switchSession
	)
	if ($switchsession.socket.Connected -and $switchSession.Authenticated) {
		if ($switchSession.EN) {
			$waittime = $switchSession.WaitTime
			Write-Progress -Activity "Gathering log data is a long process please wait"
			$commandResult = Invoke-CIOS_Command -switchsession $switchSession -Command "sh log"
			$linestart = $commandResult.IndexOf(([string]($commandResult -match "Log Buffer"))) + 2
			$logArray = @()
			for ($i = $linestart; $i -lt $commandResult.count; $i++) {
				$logObject = [pscustomobject]@{
					EventID = $commandResult[$i].split(":",2)[0].trim()
					Timestamp = $commandResult[$i].split(":",2)[1].split("%")[0].substring(0,$commandResult[$i].split(":",2)[1].split("%")[0].Length - 2).trim()
					EventName = $commandResult[$i].split(":",2)[1].split("%")[1].split(":")[0].trim()
					Description = $commandResult[$i].split(":",2)[1].split("%")[1].split(":")[1].trim()
				}
				$logarray += $logObject
			}
			$switchSession.CIOSLog = $logarray
		} else {
			throw [System.Exception]"This Function requires ENABLE"
		}
	}
	else {
		throw [System.Exception]"Please connect first `".Connect()`""
	}
}

<# 
.SYNOPSIS 
Bounces the interface on the switch

.DESCRIPTION 
Enters config terminal (config t )
Enters config interface (int <INTID>)
Shuts port (shut)
Disables poe (power inline never)
Opens port (No Shut)
Enables POE (power inline auto)

.PARAMETER switchsession
The switchSession object that you're getting data for

.PARAMETER interface
[string] the name of the interface you would like to look at

.NOTES 
 Author: Mentaleak

#>
function reset-CIOS_Interface () {
	param(
		[Parameter(mandatory = $true)] $switchSession,
		[Parameter(mandatory = $true)] [string]$interface
	)
	if ($switchsession.socket.Connected -and $switchSession.Authenticated) {
		if ($switchSession.EN) {
			$waittime = $switchSession.WaitTime
			$EnterConfigTerminal = Invoke-CIOS_Command -switchsession $switchSession -Command "config t"
			if ($EnterConfigTerminal -match "Enter configuration commands") {
				$EnterInterfaceConfig = Invoke-CIOS_Command -switchsession $switchSession -Command "int $interface"
				if ($EnterInterfaceConfig -match "int $interface") {
					$shut = Invoke-CIOS_Command -switchsession $switchSession -Command "shut"
					$powerinlinenever = Invoke-CIOS_Command -switchsession $switchSession -Command "power inline never"
					$noshut = Invoke-CIOS_Command -switchsession $switchSession -Command "no shut"
					Write-Progress -Activity "Waiting for a power Cycle" -PercentComplete 50
					Start-Sleep -Seconds 12
					$powerinlineauto = Invoke-CIOS_Command -switchsession $switchSession -Command "power inline auto"
					$endconfig = Invoke-CIOS_Command -switchsession $switchSession -Command "end"
				}
			}
		} else {
			throw [System.Exception]"Must have enable credential"
		}
	}
	else {
		throw [System.Exception]"Please connect first `".Connect()`""
	}
}



#------------------------------------------------


#Parse Config
#sh ip interface gi1/0/1



#Example
#$switchsession = New-CIOS_Session -hostname "192.168.1.1" 


