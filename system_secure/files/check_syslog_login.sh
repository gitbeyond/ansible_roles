#!/bin/bash
if [ -f /etc/syslog.conf ]; 
  then 
   cat /etc/syslog.conf | egrep  -v "^[[:space:]]*#" | egrep "authpriv" | egrep "/var/log/secure"; 
  fi; 
if [ -f /etc/rsyslog.conf ]; 
  then cat /etc/rsyslog.conf | egrep -v "^[[:space:]]*#" | egrep "authpriv" | egrep "/var/log/secure"; 
  fi
if [ -s /etc/syslog-ng/syslog-ng.conf ]; 
  then 
    fauthpriv=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "^[[:space:]]*filter" | egrep "facility[[:space:]]*\([[:space:]]*authpriv[[:space:]]*\)"| awk '{print $2}'`
    if [ -n "$fauthpriv" ];
    then 
      log_count=`cat /etc/syslog-ng/syslog-ng.conf | egrep -v "^[[:space:]]*#" | egrep "^[[:space:]]*log" | egrep $fauthpriv | wc -l`
      if [ $log_count -ge 1 ];
      then echo "result:true";
      else echo "Authpriv not config, result:false";
      exit 1
      fi
    else
      echo "No authpriv, result:false";
      exit 2
    fi
  fi
