#!/bin/bash
if ([ -d /etc/pam.d ] && [ -f /etc/pam.d/common-password ] );
  then FILE_NAME=/etc/pam.d/common-password;
    cat $FILE_NAME |sed '/^#/d'|sed '/^$/d'|egrep -i "auth[[:space:]]*required[[:space:]]*pam_tally.so|auth[[:space:]]*required[[:space:]]*pam_tally2.so|account[[:space:]]*required[[:space:]]*pam_tally.so|account[[:space:]]*required[[:space:]]*pam_tally2.so" 
  fi
if ([ -f /etc/redhat-release ] && [ -f /etc/pam.d/system-auth ]); 
  then FILE_NAME=/etc/pam.d/system-auth 
   cat $FILE_NAME |sed '/^#/d'|sed '/^$/d'|egrep -i "auth[[:space:]]*required[[:space:]]*pam_tally.so|auth[[:space:]]*required[[:space:]]*pam_tally2.so|account[[:space:]]*required[[:space:]]*pam_tally.so|account[[:space:]]*required[[:space:]]*pam_tally2.so" 
  fi 
suse_version=`cat /etc/SuSE-release 2>/dev/null|grep -i "VERSION"|awk '{print $3}'` 
if ([ "x$suse_version" = x10 ] || [ "x$suse_version" = x11 ]) 
  then 
   FILE_NAME=/etc/pam.d/common-password 
   cat $FILE_NAME|grep -v '^#'|egrep -i "auth[[:space:]]*required[[:space:]]*pam_tally.so|auth[[:space:]]*required[[:space:]]*pam_tally2.so|account[[:space:]]*required[[:space:]]*pam_tally.so|account[[:space:]]*required[[:space:]]*pam_tally2.so" 
   else 
  if [ -f /etc/SuSE-release ] 
  then 
  FILE_NAME=/etc/pam.d/passwd 
  cat $FILE_NAME|grep -v '^#'|egrep -i "auth[[:space:]]*required[[:space:]]*pam_tally.so|auth[[:space:]]*required[[:space:]]*pam_tally2.so|account[[:space:]]*required[[:space:]]*pam_tally.so|account[[:space:]]*required[[:space:]]*pam_tally2.so" 
  fi 
  fi 
unset suse_version FILE_NAME;
