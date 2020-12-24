#!/bin/bash
# editor: haifengsss@163.com
# create date: 2020/12/14
# 检查 drbd 状态

source {{keepalived_script_dir}}/drbd_keepalived_lib.sh
{%raw%}
drbd_role=$(drbdadm role ${drbd_res})
check_vip(){
    local vip=$(ip a |grep -o "${drbd_vip}")
    if [ -n "${vip}" ];then
        # 不为空时返回0
        return 0
    else
        # 为空时返回 1
        return 1
    fi
}

check_mount_point(){
    local drbd_mount=$(grep "/dev/${drbd0}.*${drbd_mount_point}" /proc/mounts) 
    if [ -n "${drbd_mount}" ];then
        # 不为空时返回0
        return 0
    else
        # 为空时返回1
        return 1
    fi
}
# 当drbd开始切换过程当中时，检测日志判断是否切换完成，切换过程当中，直接返回0
check_status_log(){
  
    if [ -e ${drbd_status_log} ];then
        :
    else
        return 0
    fi
    local dt_s=$(date +%s)
    last_log=($(tail -n 1 ${drbd_status_log}))
    last_log_ts=${last_log[0]}
    last_log_state=${last_log[1]}
    last_log_stage=${last_log[2]}
    if [ "${last_log_stage}" == "start" ];then
        # 当前时间与日志中时间的差异
        ts_diff=$((dt_s-last_log_ts))
        # 如果切换时间超过了10秒就判定为失败
        if [ ${ts_diff} -le ${check_status_log_timeout} ];then
            # 小于20秒，说明正在切换，那么就判定为成功
            exit 0
        else
            exit 20
        fi
    else
        return 0
    fi
}

check_drbd_status(){
    # 检查vip是否存在
    check_vip
    local check_vip_ret=$?
    # 检查挂载点是否存在
    check_mount_point
    local check_mount_ret=$?
    # 检查 role
    local drbd_role=$(drbdadm role ${drbd_res})
    # 设置一个状态变量
    local check_stat=""
    # vip 存在的情况下
    if [ ${check_vip_ret} == 0 ];then
        # 如果状态为 primary，那么检测成功
        if [ "${drbd_role}" == "${drbd_primary}" ];then
            #check_stat=${check_stat}0
            # 判断挂载点是否存在
            # 等于0时代表有挂载点
            if [ ${check_mount_ret} == 0 ];then
                return 0
            else
                return 1
            fi
        else
            #check_stat=${check_stat}1
            return 11
        fi
    else
    # vip 不存在的情况下
        # 如果状态为 secondary 那么，检测成功
        if [ "${drbd_role}" == "${drbd_secondary}" ];then
            #check_stat=${check_stat}0
            return 0
        else
            #check_stat=${check_stat}1
            return 2
        fi
    fi
}
check_status_log
check_drbd_status
{%endraw%}
