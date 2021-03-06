<# 
 .SYNOPSIS 
 Creates a new CIOS Session 

.DESCRIPTION 
 Instantiates a new CIOS Session object 

.PARAMETER hostname 
 string Parameter_hostname=[String] hostname or IP of the switch 

.PARAMETER Port 
 string Parameter_Port=[string] Port to connect to, default 23 

.PARAMETER WaitTime 
 string Parameter_WaitTime=[int] time to wait between line reads 

.EXAMPLE 
 $switchSession= New-CIOS_Session -hostname "testswitch.domain.local" 

.NOTES 
 Author: Mentaleak 

#> 
function New-CIOS_Session () {
 
	param(
		[Parameter(mandatory = $true)] [string]$hostname,
		[string]$Port = "23",
		[int]$WaitTime = 100
	)
	$switchSession = New-Object PSObject
	$typename = 'CIOS.Switch.Session'
	$switchSession.PSObject.TypeNames.Insert(0,$typename)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Hostname" -Value ($hostname)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Port" -Value ($Port)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "WaitTime" -Value ($WaitTime)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Socket" -Value (New-Object System.Net.Sockets.TcpClient ($hostname,$Port))
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Cred" -Value ([pscredential]::Empty)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Encred" -Value ([pscredential]::Empty)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Authenticated" -Value $false
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "UpdateTimes" -Value (New-Object -TypeName psobject)
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "IntStatus_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "MacTable_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Version_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "Config_Latest" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "CommandLog" -Value @()
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "CIOSLog" -Value $null
	Add-Member -InputObject $switchSession -MemberType NoteProperty -Name "CommandLogRaw" -Value @()

	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "Dispose" -Value {
		remove-object_Pstool -InputObject $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "Credentials" -Value {
		param([bool]$masterCredentials)
		set-CIOS_Session-Credential -switchsession $this -masterCreds $masterCredentials
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "Connect" -Value {
		Connect-CIOS_Session -switchsession $this
	} -Force

	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getIntStatus" -Value {
		get-CIOS_IntStatus -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getMacTable" -Value {
		get-CIOS_MacTable -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getConfig" -Value {
		get-CIOS_Config -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getVersion" -Value {
		get-CIOS_Version -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getDATA" -Value {
		get-CIOS_IntStatus -switchsession $this
		get-CIOS_MacTable -switchsession $this
		get-CIOS_Config -switchsession $this
		get-CIOS_Version -switchsession $this
		foreach ($port in $this.IntStatus_Latest.port) {
			$this.getIntInfo($port)
		}
		get-CIOS_log -switchsession $this
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getIntInfo" -Value {
		param([Parameter(mandatory = $true)] [string]$interface)
		get-CIOS_IntInfo -switchsession $this -interface $interface
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "RunCommand" -Value {
		param([Parameter(mandatory = $true)] [string]$command,
			[bool]$writeresult)
		Invoke-CIOS_Command -switchsession $this -Command $command -writeresult $writeresult
	} -Force
	Add-Member -MemberType ScriptMethod -InputObject $switchSession -Name "getCIOSLog" -Value {
		get-CIOS_log -switchsession $this
	} -Force


	#$switchsession.Credentials()
	return $switchSession
}
