#!/bin/bash
if [ -f /etc/syslog.conf ]; 
  then 
   cat /etc/syslog.conf | egrep -v "^[[:space:]]*#" | egrep -E '[[:space:]]*.+@.+'; 
  fi; 
if [ -s /etc/syslog-ng/syslog-ng.conf ]; 
  then 
   ret_1=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "port(514)"|awk '{print $2}'`; 
   if [ -n "$ret_1" ]; 
   then 
  ret_2=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "destination($ret_1)"`; 
   if [ -n "$ret_2" ]; 
   then 
  echo "LogServer:true"; 
   else 
  echo "LogServer:false"; 
  fi; 
  fi; 
  fi; 
if [ -f /etc/rsyslog.conf ]; 
  then cat /etc/rsyslog.conf | egrep -v "^[[:space:]]*#" | egrep -E '[[:space:]]*.+@.+'; 
fi
