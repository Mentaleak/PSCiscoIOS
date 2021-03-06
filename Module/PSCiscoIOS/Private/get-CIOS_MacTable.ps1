<# 
 .SYNOPSIS 
 Gets the mac address table 

.DESCRIPTION 
 Gets the Mac Table from the switch (show mac address-table)
Sets the data parsed into an array of custom objects into MacTable_Latest
Sets the time into UpdateTimes 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

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
