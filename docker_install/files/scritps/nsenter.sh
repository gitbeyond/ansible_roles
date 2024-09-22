#!/bin/bash
# editor: haifengsss@163.com
# 进入 docker 容器的网络名称空间执行命令

readonly netns_dir="/var/run/netns"
# arg 1: 容器名称
# arg 2: 命令行
my_nsenter(){
    local c_name="$1" cmd_string="$2"
    local c_uuid=$(docker ps -a | grep -v "/pause" | grep "${c_name}" |head -n 1 | awk '{print $1}') c_uuid_ret=$?
    if [ -n "${c_uuid}" ];then
        :
    else
        echo "the container ${c_name} isn't exist."
        return 5
    fi
    local c_pid=$(docker inspect -f {{.State.Pid}} ${c_uuid}) c_pid_ret=$?
    if [ ${c_pid_ret} -ne 0 ];then
        echo "getting the container pid is failed."
        return 6
    fi
    #nsenter -n -t ${c_pid}
    [ -d ${netns_dir} ] || mkdir -p ${netns_dir}
    local netns_link_source_file="/proc/${c_pid}/ns/net"
    local netns_link_file="${netns_dir}/${c_name}"
    if [ -h ${netns_link_file} ];then
        local current_link_source_file=$(ls -l ${netns_link_file} |awk '{print $NF}')
        if [ "${current_link_source_file}" == "${netns_link_source_file}" ]; then
            :
        else
            /bin/rm -f ${netns_link_file}
        fi
    else
        ln -sv ${netns_link_source_file} ${netns_link_file}
    fi
    ip netns exec ${c_name} /bin/bash -c "${cmd_string}"
}
my_nsenter traefik bash

