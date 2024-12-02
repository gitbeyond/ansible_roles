#!/bin/bash
# create date: 2024/12/02
# author: haifengsss@163.com
# desc: 检测nvme硬盘耐久度脚本。
# 依赖: nvme-cli dmidecode

set -euo pipefail

for nvme in `ls /dev/nvme*n1`; do
    # 获取nvme硬盘的耐久度，然后进行比较。
    used=`nvme -smart-log $nvme | grep percentage_used | awk -F ":" '{print $NF}' | awk -F "%" '{print $1}'`
    # 增加确认slot部分
    # 通过nvme盘符来确认bus id
    # 通过找到的bus id，使用dmidecode命令查看slot信息，找到nvme硬盘对应的slot。
    nvme_id=`echo $nvme | awk -F "/" '{print $3}'`
    bus_id=`ls -l /sys/class/block | grep "${nvme_id}$" | awk -F "/" '{print $(NF-3)}'`
    slot=`dmidecode -t slot | grep $bus_id -B 10 | grep Designation`
    if [ ${used} -le 85 ] ;then
        echo "${nvme} 耐久度使用 ${used}%!!"
        echo "${slot}"
    else
        echo "$nvme 耐久度使用 ${used}%!!"
        echo "${slot}"
    fi
done

