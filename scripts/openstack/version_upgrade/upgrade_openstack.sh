#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

# 使用前安装新的源，把旧的源放至 /etc/yum.repos.d/bak 目录下
dt=$(date +%Y%m%d)
old_os_version=$1
new_os_version=$2
old_os_packet=centos-release-openstack-${old_os_version}
new_os_packet=centos-release-openstack-${new_os_version}
public_if=em2
local_ip=10.111.32.127



if [ ${#} -ne 2 ];then
    echo "usage: $0 openstack_old_version openstack_new_version"
    exit 1
fi

if ip a |grep "${local_ip}" &> /dev/null && ip a |grep "${public_if}";then
    :
else
    echo "${public_if} or ${local_ip} is not exist!"
    exit 3
fi

rpm -qa |grep ${old_os_packet} && rpm -e ${old_os_packet}

if rpm -qa |grep ${new_os_packet};then
    :
else
    echo "the ${new_os_packet} isn't install. now start install."
#    exit 10
    yum -y install ${new_os_packet}
    if [ $? != 0 ];then
        echo "the ${new_os_packet} install failed."
        exit 2
    fi
fi


echo "mv /etc/neutron /etc/neutron_${old_os_version}_${dt}"
ls -d /etc/neutron_${old_os_version}* || mv /etc/neutron /etc/neutron_${old_os_version}_${dt}
echo "systemctl stop neutron-linuxbridge-agent"
systemctl stop neutron-linuxbridge-agent

echo "yum update openstack-neutron-linuxbridge ebtables ipset python2-pecan python2-cinderclient python2-os-brick"
yum update -y openstack-neutron-linuxbridge ebtables ipset python2-pecan python2-cinderclient python2-os-brick

echo "scp kvm4:/etc/neutron/neutron.conf /etc/neutron/neutron.conf"
scp kvm4:/etc/neutron/neutron.conf /etc/neutron/neutron.conf
chown root.neutron /etc/neutron/neutron.conf

echo "scp kvm4:/etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini"
scp kvm4:/etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
chown root.neutron /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "s/^\(physical_interface_mappings =\).*/\1 public:${public_if}/" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "s/^\(local_ip =\).*/\1 ${local_ip}/" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

###################
echo "mv /etc/nova /etc/nova_${old_os_version}_${dt}"
ls -d /etc/nova_${old_os_version}* || mv /etc/nova /etc/nova_${old_os_version}_${dt}
echo "systemctl stop openstack-nova-compute"
systemctl stop openstack-nova-compute
echo "yum update openstack-nova-compute"
yum -y update openstack-nova-compute
echo "scp kvm4:/etc/nova/nova.conf /etc/nova/nova.conf"
scp kvm4:/etc/nova/nova.conf /etc/nova/nova.conf
chown root.nova /etc/nova/nova.conf

sed -i "s/^\(my_ip =\).*/\1 ${local_ip}/" /etc/nova/nova.conf
