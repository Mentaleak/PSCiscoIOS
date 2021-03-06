<# 
 .SYNOPSIS 
 Invokes a command via the switch Session 

.DESCRIPTION 
 Runs a command string against the switch
Adds command to CommandLog
Returns a string array 

.PARAMETER command 
 string Parameter_command=command is a mandatory parameter of type string. [string] the command you want to run against the switch 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. The switchSession object that you're getting data for 

.PARAMETER writeResult 
 string Parameter_writeResult=writeResult is a parameter of type bool. [bool] if True, writes result to host 

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
