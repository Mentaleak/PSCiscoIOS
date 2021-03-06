<# 
 .SYNOPSIS 
 Gets the interface information from the switch 

.DESCRIPTION 
 Gets the interface Status from the switch (Show interface <INTID>)
Sets the data parsed into the portinfo field of the objects in IntStatus_Latest 

.PARAMETER interface 
 string Parameter_interface=interface is a mandatory parameter of type string. [string] the name of the interface you would like to look at 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

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
