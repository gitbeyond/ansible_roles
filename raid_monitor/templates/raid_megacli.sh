#!/bin/bash
# author: wanghaifeng
# create date: 2022/07/27
# 
# usage: 通过megacli命令生成硬件 raid 设备下的真实磁盘的健康信息
# 此脚本需要root权限来运行

set -euo pipefail

metric_textfile_base_dir="{{raid_expoter_textfile_directory}}"
# metric_textfile_base_dir="/data/apps/data/node_exporter/textfile"
# metric_name=node_raid_disk_smart_health_status
metric_file_name="megacli.prom"
metric_file_full_path="${metric_textfile_base_dir}/${metric_file_name}"
lock_file="${metric_textfile_base_dir}/.megacli.lock"
megacli_cmd="/opt/MegaRAID/MegaCli/MegaCli64"
readonly firmware_health_state=' Online, Spun Up'


# {%raw%}
check_lock(){
    if [ -d "${metric_textfile_base_dir}" ];then
        :
    else
        echo "The ${metric_textfile_base_dir} isn't exist."
        exit 6
    fi
    exec 3<> ${lock_file}
    if flock -n 3;then
        #echo "get ${lock_file} lock file."
        :
    else
        echo "get lock file failed. now exit."
        exit 5
    fi    
}
check_lock

megacli(){
    ${megacli_cmd} "${@}" -NoLog
}
# 获取raid设备数量
get_raid_dev_num(){
    local metric_value
    metric_value="$(megacli -adpCount | awk '/^Controller Count/{print $NF}' || /bin/true)"
    metric_value="${metric_value%.}"
    echo "${metric_value}"
}
# 获得raid设备的物理磁盘数量
get_raid_physical_driver_num(){
    local raid_dev_num=${1:-0}
    local metric_value
    metric_value="$(megacli -PDGetNum -a ${raid_dev_num} | awk '/^ Number of Physical Drives/{print $NF}' || /bin/true)"
    echo "${metric_value}"
}

gen_raid_dev_num(){
    local metric_name="node_megacli_raid_dev_count" metric_value
    echo "# HELP ${metric_name} the physical raid dev number"
    echo "# TYPE ${metric_name} gauge"
    # 当megacli -adpCount 返回为1时，其退出码也是1，所以这里需要处理一下
    metric_value="$(get_raid_dev_num)"
    echo "${metric_name} ${metric_value}"
}
gen_raid_physical_driver_num(){
    local metric_name="node_megacli_raid_physical_driver_count" metric_value
    echo "# HELP ${metric_name} the raid physical driver number"
    echo "# TYPE ${metric_name} gauge"
    # 当megacli -adpCount 返回为1时，其退出码也是1，所以这里需要处理一下
    metric_value="$(get_raid_physical_driver_num 0)"
    echo "${metric_name} ${metric_value}"
}

get_raid_pdinfo(){
    local metric_value
    local raid_dev_num=${1:-0}
    metric_value="$(megacli -PDList -a${raid_dev_num})"
    echo "${metric_value}"
}

echo_firmware_state_metric_help_info(){
    local metric_name="node_megacli_raid_firmware_state"
    echo "# HELP ${metric_name} the physical driver firmware state, Online, Spun Up: 1, other: 0"
    echo "# TYPE ${metric_name} gauge"
}

gen_raid_health_info(){
    local raid_info metric_value=1 metric_name="node_megacli_raid_firmware_state"
    raid_info="$(get_raid_pdinfo 0)"
    all_slot_num="$(echo "${raid_info}" | awk '/^Slot Number:/{print $NF}')"
    for i in ${all_slot_num};do
        if [ ${i} -eq 0 ];then
            echo_firmware_state_metric_help_info
        fi
        # awk -F ':' 'BEGIN{a=0}{if($0=="Slot Number: 3"){a=1}; if(a==1 && $1=="Firmware state"){b=$2; exit}}END{print b}'
        disk_state="$(echo "${raid_info}" | grep -A 18 "^Slot Number: ${i}" | awk -F':' '/^Firmware state/{print $2}')"
        if [ "${disk_state}" == "${firmware_health_state}" ];then
            :
        else
            metric_value=0
        fi
        echo "${metric_name}{slot_number=\"${i}\"} ${metric_value}"
    done
}

#gen_raid_dev_num
#gen_raid_physical_driver_num
#gen_raid_health_info


gen_metric_data(){
    local tmp_metric_file="${metric_file_full_path}_1"
    {
        gen_raid_dev_num 
        gen_raid_health_info 
        gen_raid_physical_driver_num
    } >> ${tmp_metric_file}
    [ -e ${tmp_metric_file} ] && /bin/mv ${tmp_metric_file} ${metric_file_full_path}
}


gen_metric_data

# {%endraw%}