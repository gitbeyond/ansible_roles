#!/bin/bash
# edit date:2018/03/12
# 
export PATH=/usr/lib64/qt-3.3/bin:/usr/jdk1.8.0_91/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

#log_dirs=( civp_logs service_logs )
log_dirs=( civp )
#log_type=(global global_api_inner global_api_outside)
log_type=(global_api_inner global_api_outside)

#source_base_dir=/data4/logs
source_base_dir=/data1/apps/log

month=$(date -d '-3 day' +%Y%m)
yesterday=$(date -d '-3 day' +%Y-%m-%d)
#backup_ip=172.16.8.120
civp_hosts=(172.16.9.97 172.16.9.98 172.16.9.101 172.16.9.102)
#civp_hosts=(172.16.9.97 172.16.9.98)
backup_dir=/data1/yzlog
#backup_ip_dir=$(grep "IPADDR" /etc/sysconfig/network-scripts/ifcfg-eth0 | awk -F'.'  '{print $(NF-1)"."$NF}')

#echo ${yesterday}

#for i in {3..100};do
#
#    month=$(date -d "-${i} day" +%Y%m)
#    yesterday=$(date -d "-${i} day" +%Y-%m-%d)
#    if [ ${yesterday} == "2018-01-26" ];then
#        break
#    fi
echo "-----------------------------------------"
for civp_host in ${civp_hosts[@]};do
    for dir in ${log_dirs[@]};do
        for tp in ${log_type[@]};do 
            source_dir=${source_base_dir}/${dir}/log4j2logs/${month}/${tp}
            # 进入需要打包日志的目录
#            if [ -d ${source_dir} ];then
#                echo "cd  ${source_dir}"       
#                cd ${source_dir}
#            else
#                continue
#            fi
            ip_dir=$(echo ${civp_host} | awk -F'.'  '{print $(NF-1)"."$NF}')
            # 检查目标目录是否存在，不存在则创建
            #dest_path=${backup_dir}/${dir}_logs/${ip_dir}/${month}/${tp}
            dest_path=${backup_dir}/${dir}/${ip_dir}/${month}/${tp}
#            echo "mkdir -p ${dest_path}"
            if [ -e ${dest_path} ];then
                : 
            else
                echo "mkdir -p ${dest_path}"
                mkdir -p ${dest_path}
            fi
            # 检查远程机器上的
            if ssh ${civp_host} [ -e ${source_dir}/${tp}.${yesterday}-23.log ];then
                source_file=${source_dir}/${tp}.${yesterday}-*.log
            else
                echo "the ${civp_host} ${source_dir}/${tp}.${yesterday}-23.log  is not exist. continue."
                continue
            fi

            echo ${source_file}
            # 传送日志到8.120 目录
            if [ -e ${dest_path}/${tp}.${yesterday}-23.log ];then
                echo "the ${tp}.${yesterday}-23.log is already exist ${backup_ip}:${dest_path}"
            else
                echo "`date` start scp ${civp_host}:${source_file} ${dest_path}/"
                scp ${civp_host}:${source_file} ${dest_path}/
                [ $? == 0 ] && echo "`date` scp ${yesterday} logs succeed."

            fi
#            exit 2
#            if ssh ${backup_ip} "[ -e ${dest_path}/${tp}.${yesterday}-23.log ]";then
#                echo "the ${tp}.${yesterday}-23.log is already exist ${backup_ip}:${dest_path}"
#            else
#                echo "`date` start send ${yesterday} logs."
#                scp ${source_file} ${backup_ip}:${dest_path}/
#                [ $? == 0 ] && echo "`date` send ${yesterday} logs succeed."
#            fi
            # 删除日志的操作，由 mv_log.sh 脚本完成。
            # 删除60天以前的日志
    #        old_month=$(date -d '-62 day' +%Y%m)
    #        empty_month_dir=$(date -d '-122 day' +%Y%m)
    #        old_day=$(date -d '-62 day' +%Y-%m-%d)
    #        old_file="/data4/logs/${dir}/log4j2logs/${old_month}/${tp}/${tp}.${old_day}-*.log"
    #        old_month_dir="/data4/logs/${dir}/log4j2logs/${empty_month_dir}"
    #        echo "delete old file ${old_file}"
    #        echo "delete old month dir ${old_month_dir}"
    #        echo "---------------------------"
        done
    done
done
#done
