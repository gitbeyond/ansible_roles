#!/bin/bash
if [ -f /etc/syslog.conf ] 
  then 
   echo "SYSLOG="`cat /etc/syslog.conf | egrep -v "^[[:space:]]*#" | egrep "cron.\*"` 
  fi 
if [ -f /etc/rsyslog.conf ] 
  then 
   echo "RSYSLOG="`cat /etc/rsyslog.conf | egrep -v "^[[:space:]]*#" | egrep "cron.\*"` 
  fi 
if [ -s /etc/syslog-ng/syslog-ng.conf ]; 
  then 
   cron_1=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "filter[[:space:]]*.*[[:space:]]*{[[:space:]]*facility\(cron\);[[:space:]]*};" | wc -l`; 
   if [ $cron_1 -ge 1 ]; 
  then 
  cron_2=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "destination[[:space:]]*.*[[:space:]]*{[[:space:]]*file\(\"/var/log/cron\"\)[[:space:]]*;[[:space:]]*};"|awk '{print $2}'`; 
  if [ -n $cron_2 ]; 
  then 
  cron_3=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "log[[:space:]]*{[[:space:]]*source\(src\);[[:space:]]*filter\(.*\);[[:space:]]*destination\($cron_2\);[[:space:]]*};" | wc -l`; 
   if [ $cron_3 -ge 1 ] 
  then 
  echo "corn config,result:true"; 
  else 
  echo "No log,result:false"; 
  exit 1
  fi; 
  fi; 
  fi; 
  fi;
