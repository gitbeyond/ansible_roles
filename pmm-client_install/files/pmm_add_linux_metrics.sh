#!/bin/bash
export PATH=/usr/sbin:$PATH

pmm_hostname=$(hostname -f)
pmm_local_server=$(pmm-admin info |awk '/PMM Server/{print $NF}')
pmm_server=$1
pmm_info_update=$2
pmm_info_update=${pmm_info_update:-false}
pmm_node_exporter_args=$3


pmm_linux_info=$(pmm-admin list |awk '/^linux:metrics/{print $2}')
pmm_add_config(){
    if [ "${pmm_local_server}" == "${pmm_server}" ];then
        echo "pmm_server:1"
    else
        pmm-admin config --server ${pmm_server}
    fi
}

pmm_add_linux_metrics(){
    #pmm_linux_info=$(pmm-admin list |awk '/^linux:metrics/{print $2}')
    if [ -n "${pmm_linux_info}" ];then
        echo "the linux:metrics ${pmm_linux_info} already exist. "
        pmm_add_stat=0
    else
        if [ -n "${pmm_node_exporter_args}" ];then
            pmm-admin add linux:metrics ${pmm_hostname} -- ${pmm_node_exporter_args}
            pmm_add_stat=$?
        else
            pmm-admin add linux:metrics ${pmm_hostname}
            pmm_add_stat=$?
        fi
    fi
    return ${pmm_add_stat}
}
pmm_remove_linux_metrics(){
    if [ -n "${pmm_linux_info}" ];then
        pmm-admin remove linux:metrics ${pmm_linux_info}
        pmm_rm_stat=$?
    else
        echo "the linux:metrics ${pmm_linux_info} isn't exist."
        pmm_rm_stat=0
    fi
    return ${pmm_rm_stat}
}

pmm_add_config
if [ ${pmm_info_update} == true ];then
    pmm_remove_linux_metrics
fi

pmm_add_linux_metrics
