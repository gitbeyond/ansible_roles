#!/bin/bash
ssh_banners=`cat /etc/ssh/sshd_config | egrep -v '^[[:space:]]*#' | egrep -i Banner|awk '{print $2}'`; 
ssh_status=`netstat -antp|egrep -i listen|egrep sshd|wc -l`; 
if ([ "$ssh_status" != 0 ] && [ -f "$ssh_banners" ]); 
 then 
  echo "sshd:ON.has banner.check result:true"; 
 else 
  if [ "$ssh_status" != 0 ]; 
  then 
 echo "sshd:ON.no banner.check result:false"; 
 exit 1
 else 
 echo "sshd:OFF.check result:true"; 
 fi; 
 fi; 
