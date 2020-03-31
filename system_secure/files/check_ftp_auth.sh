#!/bin/bash
ftp_status=`ps -ef|egrep -v grep|egrep -i ftpd|wc -l` 
check_state() 
{ 
  if [ -f /etc/vsftpd.conf ]; 
   then 
  ftp_config="/etc/vsftpd.conf"; 
   else 
   if [ -f /etc/vsftpd/vsftpd.conf ]; 
   then 
  ftp_config="/etc/vsftpd/vsftpd.conf"; 
  fi; 
  fi; 
  if [ -f "$ftp_config" ]; 
  then 
   if ([ `egrep -v "^#" $ftp_config|egrep -i "chroot_list_enable=YES"|wc -l` -eq 1 ] && [ `egrep -v "^#" /etc/vsftpd/vsftpd.conf|grep -i "chroot_local_user=YES"|wc -l` -eq 0 ]); 
   then 
   if [ -s "`egrep -v "^#" $ftp_config|egrep -i "chroot_list_file"|cut -d\= -f2`" ]; 
  then 
  echo "FTP:ON.check result:true" 
  else 
  echo "FTP:ON.check result:flase" 
  exit 1
  fi 
  else 
  echo "FTP:ON.check result:flase" 
  exit 2
   fi 
  fi 
  unset ftp_config; 
  } 
if [ $ftp_status -eq 0 ]; 
  then 
  echo "FTP:OFF.check result:true"; 
   else 
   check_state; 
  fi 
