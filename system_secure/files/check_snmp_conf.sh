#!/bin/bash
snmp_status=`ps -ef|egrep snmpd|egrep -v "grep"|wc -l`; 
snmp_check_fun() 
  { 
  if [ -f /etc/snmp/snmpd.conf ]; 
  then snmp_config=/etc/snmp/snmpd.conf; 
  else snmp_config=/etc/snmpd.conf; 
  fi; 
  egrep -v "^#" $snmp_config|egrep "community"; 
  if [ `egrep -v "^#" $snmp_config|egrep "rocommunity|rwcommunity"|egrep "public|private"|wc -l` -eq 0 ]; 
  then echo "SNMPD:ON.SNMP result:true"; 
  else echo "SNMPD:ON.SNMP result:false"; 
  fi; 
  } 
if [ "$snmp_status" -ge  1 ]; 
  then snmp_check_fun; 
  else echo "SNMPD:OFF.SNMP result:true"; 
  fi 
unset snmp_status snmp_config;
