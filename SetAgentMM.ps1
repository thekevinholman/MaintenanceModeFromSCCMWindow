#=================================================================================
#  Agent Maintenance Mode Script
#
#  This script simply collects info from a user and writes a parametized event for consumption by a SCOM rule
#
#  Author: Kevin Holman
#
#  Version 1.1
#=================================================================================
param([int]$Duration)

Clear-Host
Write-Host `n"Starting Agent Initiated Maintenance Mode." -ForegroundColor Yellow


#Define the event log and event source
$EvtLog = "Operations Manager"
$EvtSource = "AgentMaintenanceMode"

#Load the event source to the log if not already loaded.  This will fail if the event source is already assigned to a different log.
IF ([System.Diagnostics.EventLog]::SourceExists($EvtSource) -eq $false)
{
  [System.Diagnostics.EventLog]::CreateEventSource($EvtSource, $EvtLog)
}

# Function to create events with parameters
FUNCTION CreateParamEvent ($EvtId,$param1,$param2,$param3,$param4,$param5,$param6,$param7)
{
  $Id = New-Object System.Diagnostics.EventInstance($EvtId,1,2)
  $EvtObject = New-Object System.Diagnostics.EventLog;
  $EvtObject.Log = $EvtLog
  $EvtObject.Source = $EvtSource
  $EvtObject.WriteEvent($Id, @($param1,$param2,$param3,$param4,$param5,$param6,$param7))
}

#Get user account calling maintenance mode
[string]$WhoAmI = whoami

#Get local ComputerName
$ComputerName = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

$Error.Clear()
[string]$LogPath = "C:\Windows\Temp"
[string]$LogName = "AgentMM.log"
[string]$LogFile = $LogPath + "\" + $LogName
IF (!(Test-Path $LogPath))
{
  Write-Host `n"ERROR: Cannot access logging directory ($LogPath).  Terminating.`n" -ForegroundColor Red
  CreateParamEvent 8888 "ERROR: Cannot access logging directory ($LogPath).  Terminating."
  EXIT
}
IF (!(Test-Path $LogFile))
{
  Write-Host `n"Creating log file...." -ForegroundColor Magenta
  New-Item -Path $LogPath -Name $LogName -ItemType File | Out-Null
}
Function LogWrite
{
   Param ([string]$LogString)
   $LogTime = Get-Date -Format 'dd/MM/yy hh:mm:ss'
   Add-content $LogFile -value "$LogTime : $LogString"
}
LogWrite "*****"
LogWrite "*****"
LogWrite "*****"
LogWrite "Starting Agent Initiated Maintenance Mode script called by ($WhoAmI)"
IF ($Error) 
{ 
  LogWrite "Error ocurred.  Error is: ($Error)" 
}

LogWrite "Checking to see if the SCOM Agent is installed."
$Error.Clear()
[string]$AgentRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups"
IF (!(Test-Path -path $AgentRegPath))
{
  Write-Host `n"FATAL ERROR: SCOM Agent Not Found.  Terminating." -ForegroundColor Red
  Write-Host `n
  LogWrite "FATAL ERROR: SCOM Agent Not Found.  Terminating."
  CreateParamEvent 8888 "FATAL ERROR: SCOM Agent Not Found.  Terminating."
  EXIT
}
ELSE
{
  LogWrite "SCOM Agent is installed.  Continuing."
}
IF ($Error) 
{ 
  LogWrite "Error ocurred.  Error is: ($Error)" 
}

IF ($Duration)
{
  #We received duration as a param to the script.  Check to make sure it is valid.
  IF ($Duration -lt 5 -or $Duration -gt 99999)
  {
    #Duration is invalid.  Terminate.
    LogWrite "Duration passed as a script parameter in minutes is INVALID: ($Duration).  Terminating."
    CreateParamEvent 8888 "Duration passed as a script parameter in minutes is INVALID: ($Duration).  Terminating."
    EXIT
  }
  ELSE
  {
    #Duration is valid
    LogWrite "Duration passed as a script parameter in minutes: ($Duration)"
  }
}
ELSE
{
  #There is no duration passed to script so we must ask the user for it
  Start-Sleep -s 1

  # We need to ask for the Duration
  Write-Host `n"Getting Duration of Maintenance Mode" -ForegroundColor Magenta
  LogWrite "Getting Duration of Maintenance Mode"
  Start-Sleep -s 1
  $Duration = Read-Host -Prompt `n"Input duration in minutes from 5 to 99999"
  WHILE ($Duration -lt 5 -or $Duration -gt 99999)
  {
    Write-Host `n"You entered an invalid duration of ($Duration) minutes." -ForegroundColor Red
    [int]$Duration = Read-Host -Prompt `n"Input duration in minutes from 5 to 99999"
  }
  Write-Host `n"Duration will be set to ($Duration) minutes." -ForegroundColor Green
  LogWrite "Duration entered by user in minutes: ($Duration)"
}

[string]$Reason = "PlannedOther"
[string]$Comment = "Agent Initiated Maintenance Mode set by ($WhoAmI) for ($Duration) minutes."
$LocalTimeStamp = (get-date)

LogWrite "Reason: ($Reason)"
LogWrite "Comment: ($Comment)"
LogWrite "Local Time Stamp: ($LocalTimeStamp)"

Write-Host `n"Writing Windows Event to trigger Maintenance Mode" -ForegroundColor Magenta
CreateParamEvent 9999 "Agent Side Maintenance Mode Initiated. `nDuration in minutes: ($Duration). `nReason: ($Reason). `nComment: ($Comment). `nUser: ($WhoAmI). `nLocal Time Stamp: ($LocalTimeStamp)" "$Duration" "$Reason" "$Comment" "$WhoAmI" "$LocalTimeStamp" "$ComputerName"