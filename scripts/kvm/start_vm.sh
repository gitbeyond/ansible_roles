#!/bin/bash
export PATH=/root/nodejs/node-v7.9.0-linux-x64/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

#virsh list --all
vm=( 32_115 32_162 32_163 32_183 mysql3 mysql2 )
#vm=( hadoop1 hadoop2 hadoop3 hadoop4 32_115 32_162 32_163 32_183 mysql3 mysql2 )
for i in ${vm[@]};do
    vm_stat=$(virsh dominfo ${i} |grep "State" |awk '{print $NF}')
    if [ ${vm_stat} != "running" ];then
        echo "-----------------------------------"
        virsh start ${i}
        echo "`date` start ${i}"
    fi
done
