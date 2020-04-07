#!/bin/bash
SYSLOGD_FLAG=`ps -ef |egrep ' syslogd '|egrep -v "grep"|wc -l`; 
SYSLOGNG_FLAG=`ps -ef |egrep "syslog-ng"|egrep -v "grep syslog-ng"|wc -l`; 
RSYSLOGD_FLAG=`ps -ef | egrep "rsyslogd" | egrep -v "grep" |wc -l`; 
if [ "$SYSLOGD_FLAG" != 0 ]; 
  then 
   LOGDIR=`if [ -f /etc/syslog.conf ];then cat /etc/syslog.conf| egrep -v "^[[:space:]]*[#$]"|awk '{print $2}'|sed 's/^-//g'|egrep '^\s*\/';fi`; 
   MESSAGE_NUM=`ls -l $LOGDIR 2>/dev/null|egrep -v "[r-][w-][x-][r-]-[x-][r-]-[x-]" | awk '{print $1" "$7"  "$8" "$9}'|wc -l`;
   echo MESSAGE_NUM=$MESSAGE_NUM
   OTHER_NUM=`ls -l $LOGDIR 2>/dev/null|egrep -v "[r-][w-][x-][r-][w-][x-][r-]-[x-]" | awk '{print $1" "$7"  "$8" "$9}'|wc -l`;
   echo OTHER_NUM=$OTHER_NUM
   echo ALL_NUM=`expr $MESSAGE_NUM + $OTHER_NUM`
else 
   if [ "$RSYSLOGD_FLAG" != 0 ]; 
         then 
         LOGDIR=`cat /etc/rsyslog.conf | egrep -v "^[[:space:]]*[#$]"|awk '{print $2}'|sed 's/^-//g'|egrep '^\s*\/'`; 
         MESSAGE_NUM=`ls -l $LOGDIR 2>/dev/null|egrep -v "[r-][w-][x-][r-]-[x-][r-]-[x-]" | awk '{print $1" "$7"  "$8" "$9}'|wc -l`;
   echo MESSAGE_NUM=$MESSAGE_NUM
      OTHER_NUM=`ls -l $LOGDIR 2>/dev/null|egrep -v "[r-][w-][x-][r-][w-][x-][r-]-[x-]" | awk '{print $1" "$7"  "$8" "$9}'|wc -l`;
         echo OTHER_NUM=$OTHER_NUM
         echo ALL_NUM=`expr $MESSAGE_NUM + $OTHER_NUM`
   else 
         if [ "$SYSLOGNG_FLAG" != 0 ]; 
            then 
            LOGDIR=`cat /etc/syslog-ng/syslog-ng.conf|egrep -v "^[[:space:]]*[#$]"|egrep "^destination"|egrep file|cut -d\" -f2`; 
            MESSAGE_NUM=`ls -l $LOGDIR 2>/dev/null|egrep -v "[r-][w-][x-][r-]-[x-][r-]-[x-]" | awk '{print $1" "$7"  "$8" "$9}'|wc -l`;
      echo MESSAGE_NUM=$MESSAGE_NUM
         OTHER_NUM=`ls -l $LOGDIR 2>/dev/null|egrep -v "[r-][w-][x-][r-][w-][x-][r-]-[x-]" | awk '{print $1" "$7"  "$8" "$9}'|wc -l`;
            echo OTHER_NUM=$OTHER_NUM
            echo ALL_NUM=`expr $MESSAGE_NUM + $OTHER_NUM` 
         else 
            echo "SYSLOG:OFF"; 
         fi; 
   fi; 
fi; 
unset SYSLOGD_FLAG SYSLOGNG_FLAG RSYSLOGD_FLAG LOGDIR;
