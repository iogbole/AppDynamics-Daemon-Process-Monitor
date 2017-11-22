# AppDynamics Linux Daemon Process Monitoring Extension 

The extension monitors linux daemon processes by their (unique) service names.  PIDs are not used here as PIDs are transient in nature.  

The extension report metrics on :

1. Service Availability 
2. CPU Usage (in Percentage) of the daemon process  
3. Memory Usage (in Percentage) of the daemon process 
4. Virtual Memory Used (in MB) of the daemon process 

The processes folder contains .proc files which contains unique strings of the processes you would like to monitor, these unique strings should be  obtained from the output of ‘ps aux’. 

If you want to monitor processes from a SAP001 server for example, create a new file named SAP001.proc and input the process names in it - using newline delimiter.   

The file name is very important as it is used to categorize the metric path. I have created ADP.proc and HUB.proc to be used as examples. 

## To Install

1. Unzip the attached zip file into $MACHINE_AGENT_HOME/monitors/
2. Check the processes folder and modify the .proc files as you deem fit 
3. Restart the machine agent 
4. Wait between 3 - 5 mins, and you should begin to see metrics streaming through, like this: 

#### Metric Path: Application Infrastructure Performance|<tier_name>|Custom Metrics|Linux Processes|<.proc_file_name>|<process_name>|Availability


![Screenshot](https://user-images.githubusercontent.com/2548160/33141535-5af9e624-cfab-11e7-9c66-39c120ec95b8.png)

The script has been configured to run every 5 minutes, you may change this anytime by modify the monitors.xml :        
 [execution-frequency-in-seconds]300[/execution-frequency-in-seconds]
and restart 
