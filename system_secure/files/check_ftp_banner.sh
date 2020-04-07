#!/bin/bash 
FTP_STATUS=`ps -ef|egrep ftpd|egrep -v grep|wc -l` 
ftp_check_func () 
  { 
  if [ -f /etc/vsftpd.conf ]; 
  then 
  FTPCONF="/etc/vsftpd.conf"; 
  else 
   if [ -f /etc/vsftpd/vsftpd.conf ]; 
   then 
  FTPCONF="/etc/vsftpd/vsftpd.conf"; 
   fi; 
  fi; 
  if [ -f "$FTPCONF" ] 
  then 
   if [ `egrep -v "^[[:space:]]*#" $FTPCONF|egrep -i "banner_file"|wc -l` -ne 0 ]; 
   then 
   banner_file = `egrep -v "^[[:space:]]*#" $FTPCONF|egrep -i "banner_file"|awk -F"=( )*" '{print $2}'`
   if [ -f $banner_file ] 
    then 
    echo "FTP:ON.$FTPCONF banner_file recommended.check result:true";
   else 
    echo "FTP:ON.$FTPCONF banner_file recommended,$banner_file not exist.check result:false";
    exit 1
   fi;
   else if [ `egrep -v "^[[:space:]]*#" $FTPCONF|egrep -i "ftpd_banner"|wc -l` -ne 0 ];
   then
    echo "FTP:on.$FTPCONF banner recommended.check result:true"; 
   else 
    echo "FTP:on.$FTPCONF banner not recommended.check result:false"; 
    exit 1
   fi; 
  fi; 
  fi;
  unset FTPCONF; 
  } 
if [ $FTP_STATUS -eq 0 ]; 
  then 
   echo "FTP:off.check result:true" 
  else 
   ftp_check_func; 
  fi;
