drbd_cluster_members="gitlab-ha-1gitlab-ha-2"
drbd_res=drbd0
drbd_primary=Primary
drbd_secondary=Secondary
drbd_vip=192.168.10.1
#drbd_mount_point=/data/apps/data/gitlab
drbd_mount_point=/var/opt/gitlab
dt_s=$(date +%s)
drbd_status_log=/data/apps/log/keepalived/keepalived_drbd_status.log
drbd_peer_ip=${drbd_cluster_members/${HOSTNAME}/}
# 状态变化时需要的时间,此时间内检测脚本会直接退出0状态
check_status_log_timeout=20

# 刚开始执行脚本时，先写入一个有 start 的记录
status_log_start(){
    local dt_s=$(date +%s)
    local drbd_to_state=$1
    echo "${dt_s} ${drbd_to_state} start" >> ${drbd_status_log}
}

# 脚本结束时，写入一个有 end 的记录,防止在切换期间 check 脚本检查状态报错

status_log_end(){
    local dt_s=$(date +%s)
    local drbd_to_state=$1
    echo "${dt_s} ${drbd_to_state} end" >> ${drbd_status_log}
}

# drbd 资源切换到 secondary 状态
drbd_role_change_to_secondary(){
    local drbd_role=$(drbdadm role ${drbd_res})
    # 先判断是否为 secondary, 不是的话，切换成 secondary
    if [ "${drbd_role}" == "${drbd_secondary}" ];then
        return 0
    else
        date
        # 在改变其role之前，还应该卸载掉挂载的目录
        drbdadm secondary ${drbd_res}
        if [ $? == 0 ];then
            return 0
        else
            return 13
        fi
    fi 
}
# 卸载 drbd 的挂载
drbd_umount_dir(){
    local drbd_mount=$(grep "/dev/${drbd0}.*${drbd_mount_point}" /proc/mounts) 
    if [ -n "${drbd_mount}" ];then
        # 不为空,说明目录有挂载，将其卸载
        date
        umount ${drbd_mount_point}
        if [ $? == 0 ];then
            return 0
        else
            return 13
        fi 
    else
        # 为空时返回0
        return 0
    fi
}
# 停止使用 drbd 挂载目录的服务
gitlab_svc_stop(){
    echo "gitlab-ctl stop"
    gitlab-ctl stop
    return $?
}

# 启动使用 drbd 挂载目录的服务
gitlab_svc_start(){
    echo "gitlab-ctl start"
    gitlab-ctl start
    return $?
}

# drbd 资源切换到 primary 状态
drbd_role_change_to_primary(){
    local drbd_role=$(drbdadm role ${drbd_res})
    # 先判断是否为 master, 不是的话，切换成 master
    if [ "${drbd_role}" == "${drbd_primary}" ];then
        return 0
    else
        # 当对端也是 primary 时，将会切换失败，因此 fault 脚本一定要切换为 secondary 状态
        # 保险起见，这里也还是要使用 ssh 检查一下对端的状态
        date
        # 在改变其role之前，还应该卸载掉挂载的目录
        drbd_peer_role=$(drbdadm status ${drbd_res} | awk -F':'  '/'${drbd_peer_ip}'/{print $NF}')
        if [ "${drbd_peer_role}" == "${drbd_primary}" ];then
            ssh ${drbd_peer_ip} fuser -km ${drbd_mount_point}
            ssh ${drbd_peer_ip} drbdadm secondary ${drbd_res}
        fi
        drbdadm primary ${drbd_res}
        if [ $? == 0 ];then
            return 0
        else
            return 12
        fi
    fi 
}

# 挂载 drbd 资源到指定目录
drbd_mount_dir(){
    local drbd_mount=$(grep "/dev/${drbd_res}.*${drbd_mount_point}" /proc/mounts) 
    if [ -n "${drbd_mount}" ];then
        # 不为空时返回0
        return 0
    else
        # 为空时返回1
        #return 1
        [ -d ${drbd_mount_point} ] || mkdir -p ${drbd_mount_point}
        date
        mount /dev/${drbd_res} ${drbd_mount_point}
        if [ $? == 0 ];then
            return 0
        else
            return 13
        fi 
    fi
}
