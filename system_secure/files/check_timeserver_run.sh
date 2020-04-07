#!/bin/bash 
ntpstatus=`ps -ef|egrep "ntp|ntpd"|egrep -v grep|wc -l` 
if [ $ntpstatus != 0 ]; 
  then 
  echo "ntp:start" 
  cat /etc/ntp.conf|grep "^server"|egrep -v "127.127.1.0"|egrep -v "127.0.0.1"; 
  echo "ntpservernum="`cat /etc/ntp.conf|egrep "^server"|egrep -v "127.127.1.0"|egrep -v "127.0.0.1"|wc -l`; 
   else 
  echo "ntp:stop"
  exit 1
  fi 
unset ntpstatus ntpservernum;
