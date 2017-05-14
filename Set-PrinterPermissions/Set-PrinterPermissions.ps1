<#
.SYNOPSIS
A tiny script to add a user or group to the access control list of a printer installed on a print server.

.DESCRIPTION
The permissions on print server level are not inherited to the printers. Only new installed printers will copy the permissions.
Present printers will not get these new permissions or permission changes. This little script will add the group or user to all installed (and shared) printers. You need the subinacl Tool from Microsoft to run this script: https://www.microsoft.com/en-us/download/details.aspx?id=23510

.PARAMETER Group
Defines the user or group that will be added to the acl.

.PARAMETER Permissions
Defines the permission that the group will get. You can commit more than one permission.
Printer:
    F = Full Control
    M = Manage Documents
    P = Print

.PARAMETER Server
Defines the print server. Please use the full qualified domain name here.

.NOTES 
    File Name	: Set-PrinterPermissions.ps1
    Author		: Timo Ewiak (tew@logikkreise.de)

.EXAMPLE
.\Set-PrinterPermissions.ps1 -group "PRT_Manage-Printer-Objects_EDIT" -Permission "MP" -Server "SERVER1.DEV.LAN"
.\Set-PrinterPermissions.ps1 -group "PRT_Manage-Printer-Objects_FULL" -Permission "F" -List ".\Desktop\Printers.txt"
#>

Param (
	[Parameter(Mandatory=$true)]
    $Group,
    [Parameter(Mandatory=$true)]
    $Permission,
    [Parameter(Mandatory=$false)]
    $Server,
	[Parameter(Mandatory=$false)]
    $List
)

############## DEFINING VARIABLES START #############################
$subinacl = "$PSScriptRoot\subinacl.exe"
$LogPath = "$PSScriptRoot\Set-PrinterPermissions.log"
############## DEFINING VARIABLES END #############################

if($List)
{
	$Server = Get-Content -Path $List -Encoding UTF8 -ErrorAction Stop
}

try {    
    if($List -or $Server)
    {
        ForEach($Server in $Servers)
        {
            $Printers = Get-Printer -Computername $Server | Where-Object {$_.Published -eq $false} -ErrorAction Stop
            ForEach($Printer in $Printers)
            {
                $PrinterSharePath = "\\" + ($server).split(".")[0] + "\" + $Printer.sharename

                Write-Host $PrinterSharePath | Out-File -FilePath $LogPath -Encoding utf8 -Append -ErrorAction Stop
                $Arguments = "/printer $PrinterSharePath /Grant=$Group=$Permission"
                Start-Process -FilePath $subinacl -ArgumentList $Arguments -Wait -ErrorAction Stop
            }
        }
    }
}    
catch {
    if(!$List -or !$Server)
    {
        Write-Host "Please define a single server or a simple list. Both variables are empty."
    }
}    
