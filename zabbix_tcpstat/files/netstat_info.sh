#!/bin/bash


readonly netstat_file=/proc/net/netstat

# 获取多行文本中的其中一行数据, 好处是不需要调用外部命令
get_line(){
    local IFS=$'\n'
    local line_number=${2}
    local data="${1}"
    local count=1
    for i in ${data};do
        if [ ${count} -eq ${line_number} ];then
             echo "${i}"
             break
        fi
        count=$((count+1))      
    done
}


get_netstat_info(){
    local prop_name=""
    local netstat_info=$(< ${netstat_file})
    #echo "${netstat_info}"
    #local tcp_header=($(head -n 1 <<<"${netstat_info}"))
    local tcp_header=($(get_line "${netstat_info}" 1))
    local tcp_value=($(get_line "${netstat_info}" 2))
    local tcp_info_len=${#tcp_header[@]}
    #
    local ip_ext_header=($(get_line "${netstat_info}" 3))
    local ip_ext_value=($(get_line "${netstat_info}" 4))
    local ip_ext_info_len=${#ip_ext_header[@]}
    if [ "${prop_name}" ];then
        # such as TCPSpuriousRTOs or InMcastPkts
        return 0
    fi
    # 打印 TcpExt 信息
    for ((i=0;i<${tcp_info_len};i++));do
        if [ ${i} -eq 0 ];then
            echo "${tcp_header[${i}]}"
        else
            echo "${tcp_header[${i}]} ${tcp_value[${i}]}"
        fi
    done
}

get_netstat_info
