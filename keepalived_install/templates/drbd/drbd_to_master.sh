#!/bin/bash
# editor: haifengsss@163.com
# create date: 2020/12/14
# master 状态触发的脚本

source {{keepalived_script_dir}}/drbd_keepalived_lib.sh
{%raw%}

drbd_to_state=Master


drbd_to_master(){
    # 这个时间是等待secondary 上停止 gitlab相关的进程
    sleep 11
    drbd_role_change_to_primary
    local drbd_role_ret=$?
    if [ ${drbd_role_ret} == 0 ];then
        # drbd 成功切换为 Primary 时
        drbd_mount_dir
        drbd_mount_ret=$?
        if [ ${drbd_mount_ret} == 0 ];then
            # 启动服务的代码           
            gitlab_svc_start
        else
            return ${drbd_mount_ret}
        fi
    else
        return ${drbd_role_ret}
    fi
}
status_log_start ${drbd_to_state}
drbd_to_master
if [ $? == 0 ];then
    status_log_end ${drbd_to_state}
fi
{%endraw%}
