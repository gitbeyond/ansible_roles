#!/bin/bash

export PGPORT=5432
export PGUSER=keepalived
export PGDBNAME=keepalived
export PGPASSWORD=keepalived
export PGDATA=/data/apps/data/pgsql
export LANG=en_US.utf8
export PGHOME=/data/apps/opt/pgsql
export LD_LIBRARY_PATH=${PGHOME}/lib:/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib

export PATH=${PGHOME}/bin:$PATH:.
monitor_log="/data/apps/log/pgsql/pg_monitor.log"
dt1=$(date +%F\ %T)

SQL1="UPDATE sr_delay SET last_alive = now();"
SQL2="SELECT 1;"

# 此脚本不检查备库存活状态，如果是备库则退出
# 这么做可能会有问题，当主备切换的时候，备库刚启动时有可能还没有连接至主库成为 t 状态



write_log1(){
    local msg=$1
    echo -e "${dt1}: ${HOSTNAME} ${msg}" >> ${monitor_log}
}

debug_log1=/tmp/debug.out
debug_log(){
    echo -e "${dt1}: ${HOSTNAME} ${msg}" >> ${debug_log1}
}

psql_keepalived_execute(){
    local sql_cmd=$1
    psql -At -p ${PGPORT} -U ${PGUSER} -h 127.0.0.1 -d ${PGDBNAME} -c "${sql_cmd}"
}

standby_flg=`sudo -i -u postgres /data/apps/opt/pgsql/bin/psql -p ${PGPORT} -U postgres -At -c "select pg_is_in_recovery();"`
sql_exit_code=$?


if [ ${sql_exit_code} != 0 ];then
    write_log1 "the 'select pg_is_in_recovery();' execute failed."
    exit ${sql_exit_code}
fi

if [ ${standby_flg} == 't' ];then
 
    # echo -e "`date +%F\ %T`: This is a standby database, exit!\n" >> ${monitor_log}
    write_log1 "This is a standby database, exit!\n"
    exit 0
fi

# 主库更新 sr_delay 表
#echo ${SQL1} | psql -At -p ${PGPORT} -U ${PGUSER} -D ${PGDBNAME} >> ${monitor_log}
# psql -At -p ${PGPORT} -U ${PGUSER} -d ${PGDBNAME} -c "${SQL1}" >> ${monitor_log}
psql_keepalived_execute "${SQL1}" >> ${monitor_log}

# 判断主库是否可用
# psql -At -p ${PGPORT} -U ${PGUSER} -d ${PGDBNAME} -c "${SQL2}" 
psql_keepalived_execute "${SQL2}" 
if [ $? -eq 0 ];then
    # echo -e "`date +%F\ %T`: Primary db is health." >> ${monitor_log}
    write_log1 "Primary db is health."
    exit 0
else
    # echo -e "`date +%F\ %T`: Attention: Primary db is not health!" >> ${monitor_log}
    write_log1 "Attention: Primary db is not health!"
    exit 1
fi

