param([switch]$NoVersionCheck)

#Is module loaded; if not load
if ((Get-Module PSCiscoIOS)){return}
    $psv = $PSVersionTable.PSVersion

    #verify PS Version
    if ($psv.Major -lt 5 -and !$NoVersionWarn) {
        Write-Warning ("PSCiscoIOS is listed as requiring 5; you have version $($psv).`n" +
        "Visit Microsoft to download the latest Windows Management Framework `n" +
        "To suppress this warning, change your include to 'Import-Module PSCiscoIOS -NoVersionCheck `$true'.")
        return
    }
. $PSScriptRoot\public\New-CIOS_Session.ps1
. $PSScriptRoot\private\Connect-CIOS_Session.ps1
. $PSScriptRoot\private\get-CIOS_Config.ps1
. $PSScriptRoot\private\get-CIOS_IntInfo.ps1
. $PSScriptRoot\private\get-CIOS_IntStatus.ps1
. $PSScriptRoot\private\get-CIOS_log.ps1
. $PSScriptRoot\private\get-CIOS_MacTable.ps1
. $PSScriptRoot\private\get-CIOS_Version.ps1
. $PSScriptRoot\private\Invoke-CIOS_Command.ps1
. $PSScriptRoot\private\Invoke-CIOS_FullTermLength.ps1
. $PSScriptRoot\private\Invoke-CIOS_WaitForPrompt.ps1
. $PSScriptRoot\private\new-CIOS_Credential.ps1
. $PSScriptRoot\private\reset-CIOS_Interface.ps1
. $PSScriptRoot\private\set-CIOS_Session-Credential.ps1
Export-ModuleMember Connect-CIOS_Session
Export-ModuleMember get-CIOS_Config
Export-ModuleMember get-CIOS_IntInfo
Export-ModuleMember get-CIOS_IntStatus
Export-ModuleMember get-CIOS_log
Export-ModuleMember get-CIOS_MacTable
Export-ModuleMember get-CIOS_Version
Export-ModuleMember Invoke-CIOS_Command
Export-ModuleMember Invoke-CIOS_FullTermLength
Export-ModuleMember Invoke-CIOS_WaitForPrompt
Export-ModuleMember new-CIOS_Credential
Export-ModuleMember New-CIOS_Session
Export-ModuleMember reset-CIOS_Interface
Export-ModuleMember set-CIOS_Session-Credential
