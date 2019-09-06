#!/bin/bash
pmm_user=$1
pmm_pass=$2
pmm_socket=$3
pmm_server=$4
pmm_info_update=$5
pmm_info_update=${pmm_info_update:-false}
pmm_local_server=$(pmm-admin info |awk '/PMM Server/{print $NF}')


if [ "${pmm_info_update}" == "True" ];then
    echo "pmm-admin remove mysql"
    pmm-admin remove mysql
    [ $? == 0 ] && echo "pmm-admin remove mysql succed."
    echo "${pmm_info_update} is true. start update."
    pmm-admin add mysql --socket ${pmm_socket} --user ${pmm_user} --password "${pmm_pass}"
    exit 0
else
    echo "${pmm_info_update} is false. continue..." 
fi

if [ "${pmm_local_server}" == "${pmm_server}" ];then
    echo "pmm_server:1"
else
    pmm-admin config --server ${pmm_server}
fi
if pmm-admin list |grep "${pmm_user}:\*\{3\}\@unix(${pmm_socket})";then
    echo "mysql:1"
else
    pmm-admin add mysql --socket ${pmm_socket} --user ${pmm_user} --password "${pmm_pass}"
fi 
