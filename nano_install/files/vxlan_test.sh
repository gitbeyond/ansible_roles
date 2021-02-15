#!/bin/bash
vxlan_name=nano
# 每个主机的IP需要不一样
vxlan_ip=10.9.248.65
vxlan_id=1
# 这个组播地址是用来添加路由的，让发往这个组播地址的包走vxlan网卡
multicast_addr=224.0.0.227
# 这个是指vxlan设备的实际dev,默认是拥有默认路由的网卡
nano_cell_default_link=$(ip rou sh | \
    awk '/^default/{for(i=1;i++;i<=NF){if($i=="dev"){print $(i+1); break}}}')

# 这里为了简单，每次运行脚本都会进行删除操作
ip link del ${vxlan_name}
ip link add ${vxlan_name} type vxlan id ${vxlan_id} dstport 0 dev ${nano_cell_default_link} group 239.1.1.1
ip link set ${vxlan_name} up
ip addr add ${vxlan_ip}/24 dev ${vxlan_name}

ip rou add ${multicast_addr} via ${vxlan_ip} dev ${vxlan_name}

nano_hosts=(10.9.98.108 10.9.98.109 10.9.8.58)
for h in ${nano_hosts[@]};do
    if ip a |grep ${h} &> /dev/null; then
        :
    else
        bridge fdb append 00:00:00:00:00:00 dst ${h} dev ${vxlan_name}
    fi
done

nano_v_ip=(10.9.248.200 10.9.248.65 10.9.248.2)
for v in ${nano_v_ip[@]};do
    ping -c 1 ${v}
done
