<# 
 .SYNOPSIS 
 Sets CISCO IOS Credentials for SwitchSession 

.DESCRIPTION 
 Sets CISCO IOS Credentials for SwitchSession, based on what is in credential store or prompts user for credentials 

.PARAMETER masterCreds 
 string Parameter_masterCreds=masterCreds is a parameter of type bool. bool, use master creds? 

.PARAMETER switchsession 
 string Parameter_switchsession=switchsession is a mandatory parameter of type System.Object. The CIOS object to work on 

.NOTES 
 CIOS SwitchSession Method
 Author: Mentaleak 

#> 
function set-CIOS_Session-Credential () {
 
	param(
		[Parameter(mandatory = $true)] $switchsession,
		[bool]$masterCreds
	)
	if (!($masterCreds)) {
		$switchHostname = $switchsession.hostname
	}
	if ($switchHostname -or $SwitchHostname -eq "") {
		$credentialTarget = "CiscoIOS_$($SwitchHostname)"
	} else {
		$credentialTarget = "CiscoIOS"
	}


	try {
		$cred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_login")[0])
	}
	catch {
		new-CIOS_Credential $SwitchHostname
		try {
			$cred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_login")[0])
		} catch {}
	}



	$switchsession.cred = $cred




	try {
		$encred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_EN")[0])
	}
	catch {
		$idk = [System.Windows.Forms.MessageBox]::Show("Do You know the en creds"," Question?","YesNo")
		if ($idk -eq "Yes") {
			new-CIOS_Credential -en $SwitchHostname
			try {
				$encred = ((Find-Credential | Where-Object Target -Match "$($credentialTarget)_EN")[0])
			} catch {}
		}
	}

	$switchsession.encred = $encred





}
