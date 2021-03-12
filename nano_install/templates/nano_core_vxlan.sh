#!/bin/bash
# editor: wanghaifeng@idstaff.com
# create date: 2020/02/01
# update date: 2021/02/20
# 作用：当nano需要跨网段部署时，而物理网络又不支持组播转发，那么为各主机建立 vxlan 的通道
#      使 core 与 cell 可以正常的用组播进行通信。
#      目前来看，不需要 cell 与 cell 间通信。

# core 的实际ip地址，vxlan设备会基于这个网卡进行通信
nano_core_ph_ip={{nano_core_ph_ip}}
nano_core_vxlan_ip={{nano_core_vxlan_ip}}
nano_core_vxlan_netmask=24

# cell 的实际的网卡名称，默认的话，使用有默认路由的网卡
# 这里默认指定了一个 ansible_ssh_host的变量，存在的问题是：如果inventory中写的是主机名的方式，的话，这里会出问题
nano_cell_ph_ip={{ansible_ssh_host}}
nano_cell_ph_link=$(ip a |grep -B 2 ${nano_cell_ph_ip} | head -n 1 |awk -F:  '{gsub(" ","",$2); print $2}')
nano_cell_default_link=$(ip rou sh | \
    awk '/^default/{for(i=1;i++;i<=NF){if($i=="dev"){print $(i+1); break}}}')
nano_cell_ph_link=${nano_cell_ph_link:-${nano_cell_default_link}}
# cell 上的 vxlan ip
# 有时候会出现 cell 与 core 部署在同一台主机上
#nano_cell_vxlan_ip={{nano_cell_vxlan_ip}}
nano_cell_vxlan_ip={{nano_core_vxlan_ip}}
nano_cell_vxlan_netmask=${nano_core_vxlan_netmask}

# nano 使用的 vxlan 设备信息
nano_vxlan_id={{nano_vxlan_id | default(1)}}
nano_vxlan_name={{nano_vxlan_name | default("nano")}}
nano_vxlan_dstport={{nano_vxlan_dstport | default(0)}}
# nano 组播用的组播地址,用来设置路由
nano_multicast_address={{nano_multicast_address}}
#nano_hosts=(10.8.98.108 10.8.98.109 10.8.104.23)

# 所有的 cell hosts 的实际列表, 这个 kvm_hosts 暂时写死
nano_cell_hosts=({{groups['kvm_hosts'] | join(' ')}})
{%raw%}
nano_vxlan_group_address=239.1.1.1
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
        # 检查 vxlan 设备的 dev 是不是指定的物理网卡
        local nano_cell_now_ph_link=$(ip -d li sh ${nano_vxlan_name} | awk '/dev/{
            for(i=1;i++;i<=NF){
                if($i=="dev"){
                    print $(i+1); break
                }
            }}')
        if [ "${nano_cell_ph_link}" == "${nano_cell_now_ph_link}" ];then
            # 如果一样，什么都不做
            :
        else
            # 删除vxlan设备
            ip li del ${nano_vxlan_name}
            # 调用自身函数
            if [ $? == 0 ];then
                check_link_exist ${vxlan_ip} ${vxlan_netmask} ${nano_node_type}
            else
                echo "ip li del ${nano_vxlan_name} failed. now exit."
                return 50
            fi
        fi
        # 如果 link 设备存在的情况, 检查ip是否存在
        check_ip_exist ${vxlan_ip} ${vxlan_netmask}
    else
        # 如果 link 不存在, 先添加 link
        ip link add ${nano_vxlan_name} type vxlan \
            id ${nano_vxlan_id} dstport ${nano_vxlan_dstport} \
            dev ${nano_cell_ph_link} group ${nano_vxlan_group_address}
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
    if [ ${nano_node_type} == "cell" ];then
        bridge fdb append 00:00:00:00:00:00 dst ${nano_core_ph_ip} dev ${nano_vxlan_name}
        # 这里不 ping 一下，跟 nano_core 的 vxlan ip 是无法通信的
        # 但是却可以收到对端发往组播地址的包
        ping -c 1 ${nano_core_vxlan_ip}
    fi
}

core_add_fdb_item(){
    # 遍历 nano_cell_hosts 数组
    for cell_ip in ${nano_cell_hosts[@]};do
        if bridge fdb show dev ${nano_vxlan_name} |grep "${cell_ip}" &> /dev/null;then
            :
        else
            bridge fdb append 00:00:00:00:00:00 dst ${cell_ip} dev ${nano_vxlan_name}
            ping -c 1 ${cell_ip}
        fi
    done
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
    ping -I ${nano_cell_ph_link} -c 1 -W 2 ${nano_core_ph_ip} &> /dev/null
    local ping_ret=${?}
    if [ ${ping_ret} == 0 ];then
        # 如果ping通了，那就不做操作
        :
    else
        # 这里假设掩码都是24位的，这个是添加cell 到 core的物理路由
        local nano_core_ph_network=${nano_core_ph_ip%.*}.0/24
        # 假设网关都是1
        local nano_cell_ph_gateway=${nano_cell_ph_ip%.*}.1
        local nano_ph_route=$(ip rou sh ${nano_core_ph_network} dev ${nano_cell_ph_link} via ${nano_cell_ph_gateway}) 
        if [ -n "${nano_ph_route}" ];then
            :
        else
            # 添加物理路由
            ip rou add ${nano_core_ph_network} dev ${nano_cell_ph_link} \
                via ${nano_cell_ph_gateway}
        fi
    fi
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
        # 添加 cell 的 fdb 条目
        core_add_fdb_item
    else
        check_link_exist ${nano_cell_vxlan_ip} ${nano_cell_vxlan_netmask}
    fi
    check_route_exist
}

main


{%endraw%}
