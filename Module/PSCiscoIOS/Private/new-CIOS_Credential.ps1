<# 
 .SYNOPSIS 
 Creates new CISCO IOS Credentials 

.DESCRIPTION 
 Creates new CISCO IOS Credentials for the given hostname or will make a default one if no switchname is present
Will use better credentials stored github Credentials "CiscoIOS_<hostname>_login" and "CiscoIOS_<hostname>_en" if they exist in local keystore 

.PARAMETER en 
 string Parameter_en=en is a parameter of type switch 

.PARAMETER SwitchHostname 
 string Parameter_SwitchHostname=String will be hostname of switch credential is for if not using default 

.EXAMPLE 
 new-switchCredential Makes new default switch Credential 

.NOTES 
 Author: Mentaleak 

#> 
function new-CIOS_Credential () {
 
	param(
		[string]$SwitchHostname,
		[switch]$en
	)
	if ($switchHostname -or !($SwitchHostname -eq "")) {
		$credentialTarget = "CiscoIOS_$($SwitchHostname)"
	} else {
		$credentialTarget = "CiscoIOS"
	}
	#login
	if (!($en)) {
		$bcred = (Get-Credential -Title "Cisco IOS Login" -Description "Enter Cisco IOS login Credentials")
		if ($bcred) { Set-Credential -Credential $bcred -Target "$($credentialTarget)_login" -Description "Cisco IOS login Credential" }


	}
	#EN
	else {
		$bcred = (Get-Credential -Title "Cisco IOS EN" -Description "Enter Cisco IOS EN Credentials")
		if ($bcred) { Set-Credential -Credential $bcred -Target "$($credentialTarget)_EN" -Description "Cisco IOS login Credential" }

	}
}
