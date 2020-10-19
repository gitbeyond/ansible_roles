#!/bin/bash
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

LOGFILE=/var/log/keepalived-mysql-state.log
echo "[Backup]" >> $LOGFILE
date >> $LOGFILE

prog=`which mysql`
m_user=root
m_port=3307
m_host="127.0.0.1"
stat='show slave status\G'
#cmd3=$(/usr/bin/mysqladmin -u${m_user} -p${m_pass} -h${m_host} -P${m_port} ping 2> /dev/null| grep -c "alive")

#[ ${cmd3} != 1 ] && exit 13

sql() {
    $prog --defaults-file=/etc/keepalived/.my.cnf  -u${m_user} -P${m_port} mysql -Bse "$1"
}

sql2() {
    $prog --defaults-file=/etc/keepalived/.my.cnf -u${m_user} -P${m_port} mysql -e "$1"
}

declare -a list=($(sql "select db,name from mysql.event;"))
#list=$(sql "select db,name from mysql.event;")
#echo $list |awk '{print $1,$2}'

#echo ${list[@]}
num=$(echo ${#list[@]})

stat=$(for ((i=0;i<${num};i+=2));do
        j=$[i+1]
        echo "ALTER EVENT ${list[$i]}.${list[$j]} DISABLE ON SLAVE;"
#       echo $i
done)
#echo $stat

sql2 "set global event_scheduler=0; set sql_log_bin=0;select @@sql_log_bin; $stat" >> $LOGFILE 
echo "----------------------" >> $LOGFILE

