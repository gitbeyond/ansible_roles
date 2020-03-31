#!/bin/bash
Calculate () 
  { 
   DCREDIT=`cat $FILE_NAME|egrep -v "^#|^$"|egrep -iw "dcredit"|sed 's/^.*dcredit[[:space:]]*=[[:space:]]*//g'|sed 's/\s.*$//g'`; 
   LCREDIT=`cat $FILE_NAME|egrep -v "^#|^$"|egrep -iw "lcredit"|sed 's/^.*lcredit[[:space:]]*=[[:space:]]*//g'|sed 's/\s.*$//g'`; 
   UCREDIT=`cat $FILE_NAME|egrep -v "^#|^$"|egrep -iw "ucredit"|sed 's/^.*ucredit[[:space:]]*=[[:space:]]*//g'|sed 's/\s.*$//g'`; 
   OCREDIT=`cat $FILE_NAME|egrep -v "^#|^$"|egrep -iw "ocredit"|sed 's/^.*ocredit[[:space:]]*=[[:space:]]*//g'|sed 's/\s.*$//g'`; 
   MINLEN=`cat $FILE_NAME|egrep -v "^#|^$"|egrep -iw  "minlen"|sed 's/^.*minlen[[:space:]]*=[[:space:]]*//g'|sed 's/\s.*$//g'`;
   echo "DCREDIT=$DCREDIT"; 
   echo "LCREDIT=$LCREDIT"; 
   echo "UCREDIT=$UCREDIT"; 
   echo "OCREDIT=$OCREDIT"; 
   echo "MINLEN=$MINLEN"; 
   if [ -z $DCREDIT ]; then DCREDIT=0; else if [ $DCREDIT -lt 0 ]; then DCREDIT=1; fi; fi;
   if [ -z $LCREDIT ]; then LCREDIT=0; else if [ $LCREDIT -lt 0 ]; then LCREDIT=1; fi; fi;
   if [ -z $UCREDIT ]; then UCREDIT=0; else if [ $UCREDIT -lt 0 ]; then UCREDIT=1; fi; fi;
   if [ -z $OCREDIT ]; then OCREDIT=0; else if [ $OCREDIT -lt 0 ]; then OCREDIT=1; fi; fi;
   
   MINCLASS=`expr $DCREDIT + $LCREDIT + $UCREDIT + $OCREDIT`;
   echo "MINCLASS=$MINCLASS"
   unset DCREDIT LCREDIT UCREDIT OCREDIT MINLEN MINCLASS; 
  } 
if ([ -d /etc/pam.d ] && [ -f /etc/pam.d/common-password ] );
  then
    FILE_NAME=/etc/pam.d/common-password;
    Calculate;
  fi

if ([ -f /etc/redhat-release ] && [ -f /etc/pam.d/system-auth ]); 
  then 
   FILE_NAME=/etc/pam.d/system-auth; 
   Calculate; 
  fi 

suse_version=`cat /etc/SuSE-release 2>/dev/null|grep -i "VERSION"|awk '{print $3}'` 
if ([ "x$suse_version" = x10 ] || [ "x$suse_version" = x11 ]) 
  then 
   FILE_NAME=/etc/pam.d/common-password 
   Calculate; 
   else 
  if [ -f /etc/SuSE-release ] 
  then 
   FILE_NAME=/etc/pam.d/passwd 
   Calculate; 
  fi 
  fi
