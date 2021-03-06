<# 
 .SYNOPSIS 
 Waits for a propmpt symbol in the line feed 

.DESCRIPTION 
 Waits for a propmpt symbol in the line feed, used when waiting for the switch to finish spitting out data before entering new data 

.PARAMETER break 
 string Parameter_break=break is a parameter of type string. string, is a line to watch for that would indicate the previously entered command failed 

.PARAMETER returnError 
 string Parameter_returnError=returnError is a parameter of type string. string, error message to be displayed if the previously entered command failed (default is same as break message) 

.PARAMETER returnLine 
 string Parameter_returnLine=returnLine is a parameter of type switch. switch, if on returns line read 

.PARAMETER switchSession 
 string Parameter_switchSession=switchSession is a mandatory parameter of type System.Object. switchSession is a session object that has the details of an open session that you would like to wait for 

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
