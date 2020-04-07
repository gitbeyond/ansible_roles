#!/bin/bash
export PATH=/usr/sbin:$PATH

pmm_user=$1
pmm_pass=$2
pmm_socket=$3
pmm_server=$4
pmm_info_update=$5
pmm_info_update=${pmm_info_update:-false}
pmm_local_server=$(pmm-admin info |awk '/PMM Server/{print $NF}')
pmm_hostname=$(hostname -f)
pmm_instance_name=$6

if [ -n "${pmm_instance_name}" ];then
    pmm_instance_name=${pmm_hostname}_${pmm_instance_name}
else
    pmm_instance_name=${pmm_hostname}
fi


pmm_remove_mysql(){
    local mysql_instance=$1
    if [ -n "${mysql_instance}" ];then
        pmm-admin remove mysql ${mysql_instance}
        pmm_rm_stat=$?
    else
        pmm-admin remove mysql
        pmm_rm_stat=$?
    fi
    return ${pmm_rm_stat}
}

pmm_add_mysql(){
    local mysql_instance=$1
    if [ -n "${mysql_instance}" ];then
        :
    else
        mysql_instance=${pmm_hostname}
    fi

    pmm_select_name=$(pmm-admin list --json | jq ' .Services |map(select(.Name=="'${mysql_instance}'"))')
    if [ ${#pmm_select_name} -gt 2 ];then
        echo "the ${mysql_instance} already exist." 
        pmm_add_stat=$?
    else
        echo "pmm-admin add mysql --socket ${pmm_socket} --user ${pmm_user} ${mysql_instance}"
        pmm-admin add mysql --socket ${pmm_socket} --user ${pmm_user} --password "${pmm_pass}" ${mysql_instance}
        pmm_add_stat=$?
    fi

    return ${pmm_add_stat}
}

if [ "${pmm_local_server}" == "${pmm_server}" ];then
    echo "pmm_server:1"
else
    pmm-admin config --server ${pmm_server}
fi

# 更新操作的话，先删除，再添加
if [ "${pmm_info_update}" == "True" ];then
    echo "pmm-admin remove mysql"
    #pmm-admin remove mysql
    pmm_remove_mysql ${pmm_instance_name}
    if [ $? == 0 ];then 
        echo "pmm-admin remove mysql succed."
    else
        echo "pmm-admin remove mysql failed."
        exit 1
    fi
    #echo "${pmm_info_update} is true. start update."
    #pmm-admin add mysql --socket ${pmm_socket} --user ${pmm_user} --password "${pmm_pass}"
    #exit 0
#else
#    echo "${pmm_info_update} is false. continue..." 
fi




pmm_add_mysql ${pmm_instance_name}

#if pmm-admin list |grep "${pmm_user}:\*\{3\}\@unix(${pmm_socket})";then
#    echo "mysql:1"
