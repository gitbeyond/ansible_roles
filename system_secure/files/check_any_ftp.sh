#!/bin/bash
if [ `ps -ef|egrep ftpd|egrep -v "grep"|wc -l` -ge 1 ]; then 
   if [ -f /etc/vsftpd.conf ];then 
       cat /etc/vsftpd.conf|egrep -v "^[[:space:]]*#"|egrep -v "^[[:space:]]*$"|egrep -i "anonymous_enable"; 
       [ $? == 0 ] && exit 1
   else 
       if [ -f /etc/vsftpd/vsftpd.conf ];then 
           cat /etc/vsftpd/vsftpd.conf|egrep -v "^[[:space:]]*#"|egrep -v "^[[:space:]]*$"|egrep -i "anonymous_enable"; 
           [ $? == 0 ] && exit 1
       fi;
   fi; 
else 
   echo "ftp:off,result:true"; 
fi; 

