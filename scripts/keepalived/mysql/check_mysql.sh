#!/bin/bash

export PATH=/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
#prog="/usr/local/mysql5.6/bin/mysql"
prog=`which mysql`
m_user=root
m_host="127.0.0.1"
stat='show slave status\G'


sql() {
    $prog --defaults-file=/etc/keepalived/.my.cnf -u${m_user}  mysql -e "$1"
}


#sql "show databases;" &> /dev/null
#s1=$?
sql "select User,Host from user;"  &>/dev/null
s2=$?

if [ ${s2} != 0 ];then
    exit ${s2}
else
    exit 0
fi
