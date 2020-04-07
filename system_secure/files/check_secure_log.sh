#!/bin/bash
syslog_stat=1
if [ -f /etc/syslog.conf ]; then 
   syslog=`cat /etc/syslog.conf | egrep -v "^[[:space:]]*#" | egrep "*.err\;kern\.debug\;daemon\.notice[[:space:]]*/var/adm/messages"|wc -l`; 
   if [ $syslog -ge 1 ]; then 
       echo "SYSLOG:true"; 
       syslog_stat=0
   else 
       echo "SYSLOG:false"; 
       syslog_stat=1
   fi; 
fi; 

rsyslog_stat=1
if [ -f /etc/rsyslog.conf ];then 
   rsyslog=`cat /etc/rsyslog.conf | egrep -v "^[[:space:]]*#" | egrep "*.err\;kern\.debug\;daemon\.notice[[:space:]]*/var/adm/messages"|wc -l`; 
   if [ $rsyslog -ge 1 ];then 
       echo "RSYSLOG:true"; 
       rsyslog_stat=0
   else 
       echo "RSYSLOG:false"; 
       rsyslog_stat=1
   fi; 
fi; 

if [ -s /etc/syslog-ng/syslog-ng.conf ]; 
  then suse_ret=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "level(err) or facility(kern) and level(debug) or facility(daemon) and level(notice)"`; 
   if [ -n "$suse_ret" ]; 
   then suse_ret2=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep 'file("/var/adm/msgs")'`; 
  if [ -n "$suse_ret2" ]; 
  then suse_ret3=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "destination(msgs)"`; 
  fi; 
  fi; 
  fi; 
if [ -n "$suse_ret3" ]; 
  then echo "SUSE:true"; 
  else echo "SUSE:true"; 
  fi; 
if [ "${syslog_stat}" == 0 ] || [ "${rsyslog_stat}" == 0 ];then
    exit 0
else
    exit 1
fi
