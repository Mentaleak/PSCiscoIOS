<# 
 .SYNOPSIS 
 Gets the version information 

.DESCRIPTION 
 Gets the version data from the switch (show version)
Sets the data parsed into a custom object Version_Latest
Sets the time into UpdateTimes 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

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
