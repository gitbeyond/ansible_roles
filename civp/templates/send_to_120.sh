#!/bin/bash
# edit date:2018/11/23
# 
export PATH={{ansible_env.PATH}}

#log_dirs=( civp_logs service_logs )
log_dirs=( civp_logs )
#log_type=(global global_api_inner global_api_outside)
log_type=(global_api_inner global_api_outside)

month=$(date -d '-3 day' +%Y%m)
yesterday=$(date -d '-3 day' +%Y-%m-%d)
backup_ip=172.16.8.120
backup_dir=/data1/yzlog
default_interface=$(ip rou sh |awk '/^default/{print $NF}')
ip_conf_file="/etc/sysconfig/network-scripts/ifcfg-${default_interface}"
backup_ip_dir=$(grep "IPADDR" ${ip_conf_file} | awk -F'.'  '{print $(NF-1)"."$NF}')

#echo ${yesterday}

#for i in {5..100};do
#
#    month=$(date -d "-${i} day" +%Y%m)
#    yesterday=$(date -d "-${i} day" +%Y-%m-%d)
#    if [ ${yesterday} == "2017-05-26" ];then
#        break
#    fi
echo "-----------------------`date` begin----------------------"
for dir in ${log_dirs[@]};do
    for tp in ${log_type[@]};do 
        source_dir=/data4/logs/${dir}/log4j2logs/${month}/${tp}
        # 进入需要打包日志的目录
        if [ -d ${source_dir} ];then
            echo "cd  ${source_dir}"       
            cd ${source_dir}
        else
            continue
        fi

        # 检查 8.120 的目标目录是否存在，不存在则创建
        dest_path=${backup_dir}/${dir}/${backup_ip_dir}/${month}/${tp}
        echo "mkdir -p ${dest_path}"
        ssh ${backup_ip} "[ -e ${dest_path} ] || mkdir -p ${dest_path}" 
        
        [ -e ${tp}.${yesterday}-23.log ] && source_file=${tp}.${yesterday}-*.log
        # 传送日志到8.120 目录
        if ssh ${backup_ip} "[ -e ${dest_path}/${tp}.${yesterday}-23.log ]";then
            echo "the ${tp}.${yesterday}-23.log is already exist ${backup_ip}:${dest_path}"
        else
            echo "`date` start send ${yesterday} logs."
            scp ${source_file} ${backup_ip}:${dest_path}/
            [ $? == 0 ] && echo "`date` send ${yesterday} logs succeed."
        fi
        # 删除60天以前的日志
        old_month=$(date -d '-62 day' +%Y%m)
        empty_month_dir=$(date -d '-122 day' +%Y%m)
        old_day=$(date -d '-62 day' +%Y-%m-%d)
        old_file="/data4/logs/${dir}/log4j2logs/${old_month}/${tp}/${tp}.${old_day}-*.log"
        old_month_dir="/data4/logs/${dir}/log4j2logs/${empty_month_dir}" 
        rm -rf ${old_file}
        echo "delete old file ${old_file}"
        rm -rf ${old_month_dir}
        echo "delete old month dir ${old_month_dir}"
        echo "---------------------------"
    done
done

echo "-----------------------`date` end----------------------"
#done
