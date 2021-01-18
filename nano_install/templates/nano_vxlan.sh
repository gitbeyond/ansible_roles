#!/bin/bash
# editor: wanghaifeng@idstaff.com
# create date: 2020/01/14
# 作用：当nano需要跨网段部署时，而物理网络又不支持组播转发，那么为各主机建立 vxlan 的通道
#      使 core 与 cell 可以正常的用组播进行通信。
#      目前来看，不需要 cell 与 cell 间通信。

# core 的实际ip地址，vxlan设备会基于这个网卡进行通信
nano_core_ph_ip={{nano_core_ph_ip}}
nano_core_vxlan_ip={{nano_core_vxlan_ip}}
nano_core_vxlan_netmask=24

# cell 的实际的网卡名称，默认的话，使用有默认路由的网卡
nano_cell_ph_link=
nano_cell_default_link=$(ip rou sh | \
    awk '/^default/{for(i=1;i++;i<=NF){if($i=="dev"){print $(i+1); break}}}')
nano_cell_ph_link=${nano_cell_ph_link:-${nano_cell_default_link}}
# cell 上的 vxlan ip
nano_cell_vxlan_ip={{nano_cell_vxlan_ip}}
nano_cell_vxlan_netmask=${nano_core_vxlan_netmask}

# nano 使用的 vxlan 设备信息
nano_vxlan_id={{nano_vxlan_id | default(1)}}
nano_vxlan_name={{nano_vxlan_name | default("nano")}}
nano_vxlan_dstport={{nano_vxlan_dstport | default(0)}}
# nano 组播用的组播地址,用来设置路由
nano_multicast_address={{nano_multicast_address}}
#nano_hosts=(10.8.98.108 10.8.98.109 10.8.104.23)

{%raw%}
lock_file=/tmp/.nano_vxlan.lock
check_lock(){
    exec 3<> ${lock_file}
    if flock -n 3;then
        #echo "get ${lock_file} lock file."
        :
    else
        echo "get lock file failed. now exit."
        exit 5
    fi
}


check_link_exist(){
    # 这里声明两个
    local vxlan_ip=$1
    local vxlan_netmask=$2
    # nano 节点类型，默认是 cell
    local nano_node_type=$3
    nano_node_type=${nano_node_type:-cell}
    # 先检查 vxlan 设备是否存在
    ip li sh ${nano_vxlan_name} &> /dev/null
    local sh_ret=$?
    if [ ${sh_ret} == 0 ];then
        # 如果 link 设备存在的情况。
        check_ip_exist ${vxlan_ip} ${vxlan_netmask}
    else
        # 如果 link 不存在, 先添加 link
        # 这里 core 与 cell 在命令参数上稍有不同
        # 判断 nano 的节点类型，执行不同的命令
        #if [ "${nano_node_type}" == "cell" ];then
        #    ip link add ${nano_vxlan_name} type vxlan \
        #        id ${nano_vxlan_id} remote ${nano_core_ph_ip} \
        #        dstport ${nano_vxlan_dstport} dev ${nano_cell_ph_link}
        #    local link_add_ret=$?
        #elif [ "${nano_node_type}" == "core" ];then
        #    ip link add ${nano_vxlan_name} type vxlan \
        #        id ${nano_vxlan_id} local ${nano_core_ph_ip} \
        #        dstport ${nano_vxlan_dstport} dev ${nano_cell_ph_link}
        #    local link_add_ret=$?
        #else
        #    return 30
        #fi
        ip link add ${nano_vxlan_name} type vxlan \
            id ${nano_vxlan_id} dstport ${nano_vxlan_dstport} \
            dev ${nano_cell_ph_link} group 239.1.1.1
        local link_add_ret=$?
        ip link set ${nano_vxlan_name} up
        if [ ${link_add_ret} == 0 ];then
            # 添加 link 成功后，调用自己，添加ip
            check_link_exist ${vxlan_ip} ${vxlan_netmask} ${nano_node_type}
        else
            return ${link_add_ret}
        fi
    fi
    ip link set ${nano_vxlan_name} up
    bridge fdb append 00:00:00:00:00:00 dst ${nano_core_ph_ip} dev ${nano_vxlan_name}
    # 这里不 ping 一下，跟 nano_core 的 vxlan ip 是无法通信的
    # 但是却可以收到对端发往组播地址的包
    ping -c 1 ${nano_core_vxlan_ip}
}


check_ip_exist(){
    local vxlan_ip=$1
    local vxlan_netmask=$2
# 这一部分的逻辑 core 与 cell 都相同
    local now_vxlan_ip=$(ip a sh dev ${nano_vxlan_name} type vxlan | \
        awk '/\<inet\>/{print $2}')
    if [ -n "${now_vxlan_ip}" ];then
        if [ "${now_vxlan_ip}" == "${vxlan_ip}/${vxlan_netmask}" ];then
        # 如果 ip 地址相符
            return 0
        else 
            # 这里说明是 ip 地址不相符
            ip addr del ${now_vxlan_ip} dev ${nano_vxlan_name}
            local del_ret=$?
            if [ ${del_ret} != 0 ];then
                # 删除失败后,退出
                return 10
            fi
        fi
    fi
    # ip 为空的情况下，直接添加ip
    ip addr add ${vxlan_ip}/${vxlan_netmask} \
        dev ${nano_vxlan_name}
    
}

check_route_exist(){
    # 获取
    local route_addr=$(ip rou sh dev ${nano_vxlan_name} via ${nano_cell_vxlan_ip})
    route_addr=${route_addr% }
    if [[ -n "${route_addr}" && "${route_addr}" == ${nano_multicast_address} ]];then
        # 如果结果不为空的话
        :
    else
        ip rou add ${nano_multicast_address} dev ${nano_vxlan_name}\
            via ${nano_cell_vxlan_ip}
    fi
}

main(){
    check_lock
    if ip a |grep ${nano_core_ph_ip} &> /dev/null; then
        # 如果是 core 节点
        check_link_exist ${nano_core_vxlan_ip} ${nano_core_vxlan_netmask} core
    else
        check_link_exist ${nano_cell_vxlan_ip} ${nano_cell_vxlan_netmask}
    fi
    check_route_exist
}

main

#for h in ${nano_hosts[@]};do
#    if ip a |grep ${h} &> /dev/null; then
#        :
#    else
#        bridge fdb append 00:00:00:00:00:00 dst ${h} dev vxlan1
#    fi
#done

{%endraw%}
