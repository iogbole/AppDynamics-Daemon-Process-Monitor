#!/bin/sh

#An AppDynamics machine agent monitoring extension to monitor linux daemon processes.
#This script uses unique strings, in this case, MidddleWare service names, to monitor 4 metics: 
#1. Process Availability
#2. Process CPU Usage % 
#3. Process Memory Usage % 
#4. Process Memory Usage in MB 

#We are using a unique string from 'ps aux' output instead of the service's PID because PIDs are trasient in nature. 

#Author israel.ogbole@appdynamics.com
#version 1 : 30/10/2017

#input unique strings from the output of ps -aux here. Jon Hill advised AppD consultant to use the value of -Dsvc_name: 
process_path="processes"
#This will create this metric in all the tiers, under this path for all tiers 
metric_prefix="Custom Metrics|Linux Processes"

#This will create it in specific Tier/Component. Make sure to replace  with the appropriate one from your environment.
#To find the  in your environment, please follow the screenshot https://docs.appdynamics.com/display/PRO43/Build+a+Monitoring+Extension+Using+Java

#metric_prefix: Server|Component:|Custom Metrics|Linux Processes

proc_file_count=$(ls -1 $process_path/*.proc 2>/dev/null | wc -l)

if [ "$proc_file_count" = 0 ]; then  
      echo "This custom extension requires .proc files in the $process_path folder. Please define at least one proc file.\n Existing..."
    exit 1  
fi

for file in $process_path/*.proc; do
    #strip extension and path from fileName and use it as base_metric
    filename=${file%.*}
    metric_base="$(basename $filename)"

    while read -r proc_name; do
       
	    pid=""
        #pgrep -f is the prefered cmd as it is portable and more reliable - but not everyone got it installed 
	    if [ -x "$(command -v pgrep)" ]; then
	    	#echo "in pgrep $pid"
 			pid=$(pgrep -f $proc_name)  
		else
            pid=$(ps aux | grep $proc_name | grep -v grep | awk "{print $2}")
            #echo "pgrep is not installed  $pid"
		fi
        # echo $pid of $proc_name 
		if [ -z "$pid" ] || [ "$pid" = "" ]; then
			#service is down, send 0 to AppD 
	 		 echo "name=$metric_prefix|$metric_base|$proc_name|Availibily, value=0"
		else
			#service is up
            #ps aux header output reference 
			# USER       PID  %CPU %MEM  VSZ RSS     TTY   STAT START   TIME COMMAND
    		# get %CPU, round up or round down to approx decimal place - as metrics can only be long values 
    		cpu=$(ps aux | grep $proc_name | grep -v grep | awk '{print ($3-int($3)<0.499)?int($3):int($3)+1}')
            #get %MEM
    		mem=$(ps aux | grep $proc_name | grep -v grep | awk '{print ($4-int($4)<0.499)?int($4):int($4)+1}')
            #get used virtual used
    		virtual_mem=$(ps aux | grep $proc_name | grep -v grep | awk '{print $5}') 
            #take the first element only - make the process name unique! 
            virtual_mem=$(echo $virtual_mem | awk '{print $1}')
             
             #numerator exception handler 
            if [ -z "$virtual_mem" ] || [ "$virtual_mem" -lt 1 ]; then
                  virtual_mem_MB=$virtual_mem

            else
                #convert KB to MB
                virtual_mem_MB=$(expr $virtual_mem / 1024)
                #echo "KB: $virtual_mem, MB: $virtual_mem_MB" 
            fi
          
            #The process name must be unique! But incase it's not, take only the first value if ps aux returns more than one values.
    		metrified_cpu=$(echo $cpu | awk '{print $1}')
            metrified_mem=$( echo $mem | awk '{print $1}')
            metrified_virtual_mem=$( echo $virtual_mem_MB | awk '{print ($1-int($1)<0.499)?int($1):int($1)+1}')

    		echo "name=$metric_prefix|$metric_base|$proc_name|Availability, value=1"
    		echo "name=$metric_prefix|$metric_base|$proc_name|CPU Usage %, value=$metrified_cpu"
    		echo "name=$metric_prefix|$metric_base|$proc_name|Memory Usage %, value=$metrified_mem"
    		echo "name=$metric_prefix|$metric_base|$proc_name|Memory Usage MB, value=$metrified_virtual_mem"

		fi
   done < "$file"
done


