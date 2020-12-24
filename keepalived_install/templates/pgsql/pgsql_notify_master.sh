#!/bin/bash

export PGPORT=5432
export PGUSER=keepalived
export PG_OS_USER=postgres
export PGDBNAME=keepalived
export PGPASSWORD=keepalived
export PGDATA=/data/apps/data/pgsql
export LANG=en_US.utf8
export PGHOME=/data/apps/opt/pgsql
export LD_LIBRARY_PATH=${PGHOME}/lib:/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib

export PATH=${PGHOME}/bin:$PATH:.
monitor_log="/data/apps/log/pgsql/pg_monitor.log"

cluster_addrs=(10.6.38.115 10.6.38.116)
# keepalived vrrp 的脚本日志
pgsql_keep_log=/data/apps/log/keepalived/keepalived_pgsql_state.log
dt2=$(date +%Y%m%d%H%M%S)
keep_state="Master"
[ -d $(dirname ${pgsql_keep_log}) ] || mkdir $(dirname ${pgsql_keep_log})
echo "${dt2} ${keep_state}" >> ${pgsql_keep_log}




# 设置变量, LAG_MINUTES指允许的主备延迟时间，单位秒
dt1=$(date +%F\ %T)
LAG_MINUTES=60
HOST_IP=`hostname -i`
NOTICE_EMAIL="wanghaifengsss@geotmt.com"
FAILOVE_LOG='/data/apps/log/pgsql/pg_failover.log'

SQL1="SELECT 'this_is_standby' AS cluster_role FROM (SELECT pg_is_in_recovery() AS std ) t WHERE t.std is true;"
SQL2="select 'standby_in_allowed_lag' AS cluster_lag FROM sr_delay WHERE now()-last_alive < interval '${LAG_MINUTES} SECONDS';"

# 配置对端远程管理卡IP地址,用户名，密码

#FENCE_IP=10.111.32.91
FENCE_USER=root
#FENCE_PWD=123456

write_log1(){
    local msg=$1
    echo -e "${dt1}: ${HOSTNAME} ${msg}" >> ${monitor_log}
}

write_log_failover(){
    local msg=$1
    echo -e "${dt1}: ${HOSTNAME} ${msg}" >> ${FAILOVE_LOG}
}

# VIP 已发生漂移，记录到日志文件
# echo -e "${dt1}: keepalived VIP switchover!" >> $FAILOVE_LOG
write_log_failover "master notify. keepalived VIP switchover!"

# VIP 已漂移，邮件通知
# 尚未实现


# pg_failover 函数，当主库故障时激活备库
pg_failover(){
    # FENCE_STATUS 表示通过远程管理卡关闭主机成功标志， 1 表示失败，0表示成功
    # PROMOTE_STATUS 表示激活备库成功标志，1 表示失败，0 表示成功
    # 激活备库前需要通过远程管理卡关闭主库主机
    
        # 使用ipmitool 命令连接对端远程管理卡关闭主机，不同X86设备命令可能不一样
        #ipmitool -I lanplus -L OPERATOR -H ${FENCE_IP} -U ${FENCE_USER} -P ${FENCE_PWD} power reset
        # 关于这里的 ipmitool 的操作，有些设备可能没有远程管理卡，会改用 ssh 连上去进行操作
        # 另外示例中只是给了 notify_master 的操作，自己定义时还会定义一 notify_backup, notify_fault, notify_stop 等操作。


    for h in ${cluster_addrs[@]};do
        if [ "${h}" == "${HOST_IP}" ];then
            continue
        fi
        for((k=0;k<5;k++));do
            ssh ${FENCE_USER}@${h} /bin/bash /data/apps/var/pgsql/pgsql_notify_backup.sh

            if [ $? -eq 0 ];then
                #echo -e "${dt1}: fence primary db host success."
                write_log_failover "fence primary db host success."
                FENCE_STATUS=0
                break
            fi
            sleep 1
        done
    done
    


    if [ ${FENCE_STATUS} -ne 0 ];then
        #echo -e "${dt1}: fence failed. Standby will not promote, please fix it manually."
        write_log_failover "fence failed. Standby will not promote, please fix it manually."
        return ${FENCE_STATUS}
    fi

    # 激活备库
    su - ${PG_OS_USER} -c "pg_ctl promote"
    if [ $? -eq 0 ];then
        #echo -e "${dt1}: ${HOSTNAME} promote standby success."
        write_log_failover "promote standby success."
        PROMOTE_STATUS=0
    fi 

    if [ ${PROMOTE_STATUS} -ne 0 ];then
        # echo -e "${dt1}: promote standby failed."
        write_log_failover "promote standby failed."
        return ${PROMOTE_STATUS}

    fi

    #echo -e "${dt1}: pg_failover() function call success."
    write_log_failover "pg_failover() function call success."
    return 0

}


# 故障切换过程
# 备库是否正常的标记，STANDBY_CNT=1 表示正常
STANDBY_CNT=$(psql -At -p ${PGPORT} -h 127.0.0.1 -U ${PGUSER} -d ${PGDBNAME} -c "${SQL1}" |grep -c this_is_standby )
#echo -e "STANDBY_CNT: ${STANDBY_CNT}" >> ${FAILOVE_LOG}
write_log_failover "STANDBY_CNT: ${STANDBY_CNT}"

if [ ${STANDBY_CNT} -ne 1 ];then
    # echo -e "${dt1}: ${HOSTNAME} is not standby database, failover not allowed!" >> ${FAILOVE_LOG}
    write_log_failover "is not standby database, failover not allowed!"
    exit 1
fi

# 备库延迟时间是否在接受范围内， LAG=1 表示备库延迟时间在指定范围
LAG=$(psql -At -p ${PGPORT} -h 127.0.0.1 -U ${PGUSER} -d ${PGDBNAME} -c "${SQL2}" | grep -c standby_in_allowed_lag)
# echo -e "LAG: ${LAG}" >> ${FAILOVE_LOG}
write_log_failover "LAG: ${LAG}"

if [ $LAG -ne 1 ];then
    #echo -e "${dt1}: ${HOSTNAME} is laged far ${LAG_MINUTES} SECONDS from primary, failover not allowed!" >> ${FAILOVE_LOG}
    write_log_failover "is laged far ${LAG_MINUTES} SECONDS from primary, failover not allowed!"

    exit 1
fi

# 同时满足两个条件执行主备切换函数： 1. 备库正常；2. 备库延迟时间在指定范围内

if [ ${STANDBY_CNT} -eq 1 ] && [ ${LAG} -eq 1 ];then
    pg_failover >> ${FAILOVE_LOG}
    if [ $? -ne 0 ];then
        write_log_failover "pg_failover failed."
        exit 1
    fi 
fi

# 判断是否执行故障切换 pg_failover 函数
# 1. 当前数据库为备库，并且可用。
# 2. 备库延迟时间在指定范围内

# pg_failover 函数处理逻辑
# 1. 通过远程管理卡(或 ssh ,这里还会添加一个自己关闭的脚本操作)关闭主库主机
# 2. 激活备库
