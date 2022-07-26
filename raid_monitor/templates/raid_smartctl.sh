#!/bin/bash
# author: wanghaifeng
# create date: 2022/07/26
# usage: 生成硬件 raid 设备的smart 健康数据
# 此脚本需要root权限来运行

set -euo pipefail

metric_textfile_base_dir="{{raid_expoter_textfile_directory}}"
# {%raw%}
# metric_textfile_base_dir="/data/apps/data/node_exporter/textfile"
smart_use_json_format=0
metric_name=node_raid_disk_smart_health_status
metric_file_name="smartctl.prom"
metric_file_full_path="${metric_textfile_base_dir}/${metric_file_name}"
lock_file="${metric_textfile_base_dir}/.smartctl.lock"



# 获取磁盘信息
get_disk_info(){
    if [[ ${smart_use_json_format} == 1 ]];then
        smartctl --scan -j
    else
        smartctl --scan
    fi
}

metric_help_info(){
    echo "# HELP ${metric_name} status, 0 : error, 1 : health"
    echo "# TYPE ${metric_name} gauge"
}

# 生成监控信息

generate_monitor_data(){
    local raid_dev_name="${1}"
    local device_type="${2}"
    local device_num="${device_type#*,}"
    local metric_value="${3}" 
    echo "${metric_name}{raid_dev_name=\"${raid_dev_name}\",device_num=\"${device_num}\"} ${metric_value}"
}

#generate_monitor_data /dev/sda megaraid,3 1

generate_monitor_file(){
    local smart_scan_info raid_dev_name raid_dev_types health_str
    smart_scan_info="$(get_disk_info)"
    # echo "${smart_scan_info}"
    # 可能会有多个 raid 设备，目前仅考虑一个的情况
    raid_dev_name="$(echo "${smart_scan_info}" | awk '{if(NF==7){print $1}}')"
    #echo "${raid_dev_name}"
    raid_dev_types="$(echo "${smart_scan_info}" | awk '{if(NF==8){print $3}}')"
    local health_value=1
    metric_help_info
    for num in ${raid_dev_types};do
        health_str="$(smartctl -d "${num}" -H "${raid_dev_name}" | awk '/^SMART Health Status/{print $4}')"
        if [[ "${health_str}" = "OK" ]];then
            :
        else
            health_value=0
        fi
        generate_monitor_data ${raid_dev_name} ${num} ${health_value} >> ${metric_file_full_path}_01 
    done
    [ -e ${metric_file_full_path}_01 ] && /bin/mv ${metric_file_full_path}_01 ${metric_file_full_path}
}

main(){
    exec 3<> ${lock_file}
    if flock -n 3;then
        #echo "get ${lock_file} lock file."
        :
    else
        echo "get lock file failed. now exit."
        exit 5
    fi
    generate_monitor_file
    
}
main
# {%endraw%}