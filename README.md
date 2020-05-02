# MaintenanceModeFromSCCMWindow
SCOM - Agent Initiated Maintenance mode with SCCM Maintenance Windows

https://kevinholman.com/2019/07/28/scom-agent-initiated-maintenance-mode-with-sccm-maintenance-windows/

#### The Demo.SCOM.AgentMaintenanceMode MP has two working parts:
1.	A Management Pack
2.	An agent side PowerShell Script

The Agent side script simply creates a special parameterized event to trigger Maintenance Mode, which is monitored for by the MP.
The event must be created with the following criteria:

- Event Log: Operations Manager
- Event ID: 9999
- Event Source: AgentMaintenanceMode
- Param2: An integer for the duration between 5 and 99999 minutes
- Param3: Hard coded to “PlannedOther” for the Reason
- Param4: A comment which is required by the SCOM Maintenance Mode command.
- Param5: The User ID which ran the script to create the event
- Param6: The local time stamp in standard DateTime format
- Param7: The local Computer Name in FQDN format

The Management Pack contains a rule to watch for event 9999 and will run a response on the Management Server, in the form of a PowerShell script, which will take the parameters from the event, and will start maintenance mode for the agent.

The “trigger” event 9999 could be created by any tool desired, it does not have to be the PowerShell script included by example.  The script does some error checking to ensure valid parameters are created, however.

The script will present a UI to the user if called with no parameters and wait for input.

If you wish to run the script in an automated fashion, you simply need to provide a single param to the script, which is the Duration, which must be an integer from 5 to 99999.  The script could be modified to accept a default duration if desired.

If there is any error on the Management Server side, there is an alert rule included in the MP to generate alerts on script errors.

Additionally – there is a Rule which can be enabled to monitor for SCCM Maintenance Windows on SCCM clients, and will create the parametized event 9999 to trigger maintenance mode automatically.  This rule runs a script every 10 minutes, and queries WMI to find the upcoming maintenance windows.  This could be further customized to meet your needs.
