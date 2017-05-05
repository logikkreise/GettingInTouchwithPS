<#
.SYNOPSIS
Downloads the Trusted Root Authority Certificates, Untrusted Certificates List, Revocation Lists and Root List Signer Lists.

.DESCRIPTION
The Trusted Root Authority Certificates, Untrusted Certificates List, Revocation Lists and Root List Signer Lists are by default downloaded and updated by windows update.
This script downloads the neccessary files from windows update and saves them on a central destination, so the files can be imported by group policy settings.

.PARAMETER proxy
If defined as true, the script sets an proxy server and deletes these settings after.

.PARAMETER share
This parameter is mandatory and is used to place the downloaded files within the network.

.NOTES 
    File Name	: Update-WindowsCertificateStore.ps1
    Author		: Timo Ewiak (tew@logikkreise.de)

.EXAMPLE
.\Update-WindowsCertificateStore.ps1
.\Update-WindowsCertificateStore.ps1 -proxy proxy:80 -share \\DEV.LAN\system$\RootCertificates
#>

Param (
	[Parameter(Mandatory=$true)]
    $share,
    [Parameter(Mandatory=$false)]
    $proxy
)

############## DEFINING VARIABLES START #############################
$certutil = "C:\Windows\System32\certutil.exe"
$Arguments = "-syncWithWU $share"
$netsh = "C:\Windows\System32\netsh.exe"
$ProxySet = "winhttp set proxy proxy-server=$proxy"
$ProxyRemove = "winhttp reset proxy"
############## DEFINING VARIABLES END #############################

if (![System.Diagnostics.EventLog]::SourceExists("Update-WindowsCertificateStore"))
{
    New-EventLog -LogName "Application" -Source "Update-WindowsCertificateStore"
}

# Delete the old files within the share
Remove-Item "$share\*" -Recurse -Force -ErrorAction Stop

# Set the proxy if the variable is defined
if($proxy -ne $null){

    Start-Process -FilePath $netsh -ArgumentList $ProxySet -Wait -NoNewWindow -ErrorAction Stop
}

# Tests if it can reach the download servers from microsoft.
# Starts the download of the neccessary files and saves them to the defined network share.
if(Test-NetConnection ctldl.windowsupdate.com){

    $log = Start-Process -FilePath $certutil -ArgumentList $Arguments -Wait -NoNewWindow -ErrorAction Stop -PassThru
    #$log.ExitCode | Out-File -FilePath "$PSScriptRoot\error.txt"
    $errorcode = $log.ExitCode
    
	# Write Event-Log-Entry if success
    if($log.ExitCode -eq "0")
    {
        Write-EventLog -LogName Application -source Update-WindowsCertificateStore -eventID 41020 -EntryType Information -message "Successfully downloaded the Trusted Root Authority Certificates, Untrusted Certificates List, Revocation Lists and Root List Signer Lists." -ErrorAction Stop
    }

	# Write Event-Log-Entry if error
    if($log.ExitCode -ne "0")
    {
        Write-EventLog -LogName Application -source Update-WindowsCertificateStore -eventID 41020 -EntryType Error -message "Something went wrong. Could not download the files from microsoft, cause error code: $errorcode" -ErrorAction Stop
    }
}

# Delete the proxy after usage and if the variable is defined
if($proxy -ne $null){

    Start-Process -FilePath $netsh -ArgumentList $ProxyRemove -Wait -NoNewWindow -ErrorAction Stop
}

