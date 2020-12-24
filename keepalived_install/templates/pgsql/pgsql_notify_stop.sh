#!/bin/bash

export PGPORT=5432
export PGUSER=keepalived
export PG_OS_USER=postgres
export PGDBNAME=keepalived
export PGDATA=/data/apps/data/pgsql
export LANG=en_US.utf8
export PGHOME=/data/apps/opt/pgsql
export LD_LIBRARY_PATH=${PGHOME}/lib:/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib

export PATH=${PGHOME}/bin:$PATH:.
monitor_log="/data/apps/log/pgsql/pg_monitor.log"
FAILOVE_LOG='/data/apps/log/pgsql/pg_failover.log'

# keepalived vrrp 的脚本日志
pgsql_keep_log=/data/apps/log/keepalived/keepalived_pgsql_state.log
dt2=$(date +%Y%m%d%H%M%S)
keep_state="Stop"
[ -d $(dirname ${pgsql_keep_log}) ] || mkdir $(dirname ${pgsql_keep_log})
echo "${dt2} ${keep_state}" >> ${pgsql_keep_log}


write_log1(){
    local msg=$1
    echo -e "${dt1}: ${HOSTNAME} ${msg}" >> ${monitor_log}
}

write_log_failover(){
    local msg=$1
    echo -e "${dt1}: ${HOSTNAME} ${msg}" >> ${FAILOVE_LOG}
}

# 设置变量, LAG_MINUTES指允许的主备延迟时间，单位秒
dt1=$(date +%F\ %T)
LAG_MINUTES=60
HOST_IP=`hostname -i`
NOTICE_EMAIL="wanghaifengsss@geotmt.com"
FAILOVE_LOG='/data/apps/log/pgsql/pg_failover.log'

SQL1="SELECT 'this_is_standby' AS cluster_role FROM (SELECT pg_is_in_recovery() AS std ) t WHERE t.std is true;"

# 配置对端远程管理卡IP地址,用户名，密码
# FENCE_IP=10.111.32.91
# FENCE_USER=root
# FENCE_PWD=123456

# VIP 已发生漂移，记录到日志文件
#echo -e "${dt1}: keepalived VIP switchover!" >> $FAILOVE_LOG
write_log_failover "stop notify. keepalived VIP switchover!"

# VIP 已漂移，邮件通知
# 尚未实现

SQL1="SELECT pg_is_in_recovery();"

sql_execute(){
    local sql_words=$1
    psql -At -p ${PGPORT} -U ${PGUSER} -d ${PGDBNAME} -c "${sql_words}"
}

# 这个脚本是 notify_backup 时触发的
#   从 fault 状态转为 backup 状态
#   从 master 状态转为 失败状态

# 主库检测失败时，执行 stop 操作


# keepalived 停止时，检测当前库是否主库，是主库则停止，使其发生切换
pgsql_svc_stop(){
    # [root@test-lvs-02 ~]# sudo -u postgres -i pg_ctl status
    # pg_ctl: no server running
    # [root@test-lvs-02 ~]# echo $?
    # 3
    # systemctl 获取 postgresql 状态时，如果其是停止的，状态码为 3
    write_log_failover "systemctl stop postgresql"
    systemctl status postgresql && systemctl stop postgresql
    write_log_failover "pg_ctl stop"
    sudo -i -u ${PG_OS_USER} pg_ctl status && sudo -i -u ${PG_OS_USER} pg_ctl stop -m fast
}

# 触发 backup 时库为主库
master_to_stop(){
    # 首先判断是否是主库 , f 为主，t 为从
    standby_flag=$(sql_execute "${SQL1}")
    if [ "${standby_flag}" == "f" ];then
        pgsql_svc_stop
    else
        # 不是主库什么都不做
        :
    fi
}

# 当 keepalived 停止时，也会把 pgsql 给停掉
pgsql_svc_stop