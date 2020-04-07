#!/bin/bash
/sbin/chkconfig --list |egrep "telnet|ssh" 
ps -ef|egrep "sshd"|egrep -v "grep" 
telnetnum=`/sbin/chkconfig --list |egrep "*.telnet:"|egrep -i "on|启用"|wc -l` 
sshnum=`ps -ef|egrep "sshd"|egrep -v "grep"|wc -l` 
echo "telnetnum=${telnetnum}"
echo "sshnum=${sshnum}"

if [ "${telnetnum}" == "0" ] && [ ${sshnum} -gt 0 ];then
    exit 0
else
    exit 1
fi

unset telnetnum sshnum
