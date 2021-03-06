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

.PARAMETER interface 
 string Parameter_interface=interface is a mandatory parameter of type string. [string] the name of the interface you would like to look at 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

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
