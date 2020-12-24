#!/bin/bash
# editor: haifengsss@163.com
# create date: 2020/12/14
# Fault 状态触发的脚本

#set -euo pipefail

source {{keepalived_script_dir}}/drbd_keepalived_lib.sh
{%raw%}

drbd_to_state=Stop


drbd_to_backup(){
    # 1. 停止服务
    # 2. 卸载目录
    # 3. drbd切换为secondary
    set -e
    gitlab_svc_stop
    gitlab_svc_stop_ret=$?
    drbd_umount_dir
    drbd_umount_ret=$?
    drbd_role_change_to_secondary   
    local drbd_role_ret=$?
    set +e
}
status_log_start ${drbd_to_state}
drbd_to_backup
status_log_end ${drbd_to_state}
{%endraw%}
