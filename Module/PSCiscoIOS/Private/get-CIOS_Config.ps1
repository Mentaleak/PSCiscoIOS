<# 
 .SYNOPSIS 
 Gets the device Config 

.DESCRIPTION 
 Gets the iconfiguration from the switch (show config)
Sets the data into config_Latest
Sets the time into UpdateTimes 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

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
