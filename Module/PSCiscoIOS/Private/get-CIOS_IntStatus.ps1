<# 
 .SYNOPSIS 
 Gets the interface Status from the switch 

.DESCRIPTION 
 Gets the interface Status from the switch (Show interface Status)
Sets the data parsed into an array of custom objects into IntStatus_Latest
Sets the time into UpdateTimes 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

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
