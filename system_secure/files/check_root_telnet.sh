#!/bin/bash
/sbin/chkconfig --list |egrep "telnet"
Telnet_Status=`/sbin/chkconfig --list|egrep "telnet.*"|egrep "on|启用"|wc -l`
if [ $Telnet_Status -ge 1 ]; then
    echo "PTS_NUM="`cat /etc/securetty|grep -v "^[[:space:]]*#"|egrep "pts/*"|wc -l`
    exit 1
else
    echo "Telnet:OFF"
    exit 0
fi
