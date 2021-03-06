<# 
 .SYNOPSIS 
 Gets the log for the CIOS switch 

.DESCRIPTION 
 Gets the logs from the switch (Show log)
Sets the data parsed into the CIOSLog field of the switchsession 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

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
