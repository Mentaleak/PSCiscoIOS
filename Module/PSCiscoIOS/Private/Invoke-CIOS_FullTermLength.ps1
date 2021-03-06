<# 
 .SYNOPSIS 
 Extends Terminal length 

.DESCRIPTION 
 Extends Terminal length so that there isn't need for input to scroll 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object.switchSession is a session object that has the details of an open session that you would like to wait for 

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
