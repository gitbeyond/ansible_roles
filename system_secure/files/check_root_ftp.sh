#!/bin/bash 
FTP_STATUS=`ps -ef|egrep ftpd|egrep -v "grep "|wc -l`; 
ftp_check_func2 () 
  { 
  if [ -f /etc/vsftpd.conf ]; 
   then 
  FTP_CONF="/etc/vsftpd.conf"; 
   FTP_USER=`cat $FTP_CONF|egrep -v "^#"|egrep userlist_file|cut -d= -f2`; 
   vsftpconf_check; 
   else 
   if [ -f /etc/vsftpd/vsftpd.conf ]; 
   then 
  FTP_CONF="/etc/vsftpd/vsftpd.conf"; 
   FTP_USER=`cat $FTP_CONF|egrep -v "^#"|egrep userlist_file|cut -d= -f2`; 
   vsftpconf_check; 
  fi; 
  fi; 
  } 
vsftpconf_check () 
  { 
  userlist_enable=`egrep -v "^#" $FTP_CONF|egrep -i "userlist_enable=YES"|wc -l`; 
  userlist_deny=`egrep -v "^#" $FTP_CONF|egrep -i "userlist_deny=NO"|wc -l`; 
  if  [ $userlist_enable = 1 -a $userlist_deny = 1 ]; 
  then 
   if [ -n "$FTP_USER" ] 
   then 
  if [ `egrep -v "^#" $FTP_USER|egrep "^root$"|wc -l` = 0 ]; 
   then 
  echo "FTP:on.$FTPUSERS_PAM not recommended."$FTP_USER" recommended.check result:true"; 
   else 
  echo "FTP:on.$FTPUSERS_PAM and "$FTP_USER" not recommended.check result:false"; 
  exit 1
   fi; 
   else 
  echo "FTP:on.$FTPUSERS_PAM not recommended."$FTP_USER" not exist.check result:false"; 
   exit 1
   fi; 
  else 
   echo "FTP:on.$FTPUSERS_PAM, userlist_enable and userlist_deny not recommended.check result:false"; 
   exit 1
  fi; 
  } 
ftp_check_func1 () 
  { 
  if [ -f  /etc/pam.d/vsftpd ]; 
   then 
   FTPUSERS_PAM=`egrep "file" /etc/pam.d/vsftpd|egrep -v "^#"|sed 's/^.*file=//g'|awk '{print $1}'` 
  if [ -n "$FTPUSERS_PAM" ] 
  then 
  if [ `egrep -v "^#" $FTPUSERS_PAM|egrep "^root$"|wc -l` = 1 ]; 
   then 
  echo "FTP:on.$FTPUSERS_PAM recommended.check result:true"; 
   else 
  ftp_check_func2; 
   fi 
  else 
  ftp_check_func2; 
  fi 
   else 
   echo "/etc/pam.d/vsftpd not exist"; 
  ftp_check_func2; 
  fi;
  } 
if [ $FTP_STATUS -eq 0 ]; 
  then  echo "FTP:off.check result:true"; 
   else  ftp_check_func1; 
  fi 
unset FTP_STATUS FTP_CONF FTP_USER FTPUSERS_PAM
