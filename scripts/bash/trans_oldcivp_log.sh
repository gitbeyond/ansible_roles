#!/bin/bash
# edit date:2017/06/29
# 
export PATH=/usr/lib64/qt-3.3/bin:/usr/jdk1.8.0_91/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

HOST=""
USER=""
PASS=""
#log_dirs=( civp_logs service_logs )
log_dirs=( civp_logs )
#log_dirs=( service_logs )
#log_dirs=( civp_logs )
#log_type=(global global_api_inner global_api_outside)
log_type=(global_api_inner global_api_outside)
ip_list=(9.45 9.46 9.52 9.53 9.112 9.113)
#ip_list=(9.46)
#ip_list=( 9.113)
#ip_list=(9.112 9.113)
#ip_list=( 9.52 )

source_base_dir=/data1/yzlog
dest_base_dir=/data3/logs
month=$(date -d '-3 day' +%Y%m)
yesterday=$(date -d '-3 day' +%Y-%m-%d)



#echo ${yesterday}

#for i in {2..100};do
#
#    month=$(date -d "-${i} day" +%Y%m)
#    yesterday=$(date -d "-${i} day" +%Y-%m-%d)
#    if [ ${yesterday} == "2017-08-22" ];then
#        break
#    fi
echo "`date`#####################################"
for dir in ${log_dirs[@]};do
    for ip_dir in ${ip_list[@]};do
        for tp in ${log_type[@]};do 

            source_dir=${source_base_dir}/${dir}/${ip_dir}/${month}/${tp}
            # 进入需要打包日志的目录
            if [ -d "${source_dir}" ];then
                echo "cd  ${source_dir}"
                cd  ${source_dir}
            else
                continue
            fi
            # 检查打包的目标目录是否存在，不存在则创建
            dest_dir=${dest_base_dir}/${dir}/${ip_dir}/${month}/${tp}
            [ -e "${dest_dir}" ] || mkdir -p ${dest_dir}

            gz_file_name="${ip_dir}_${tp}.${yesterday}.tgz"
            # 检查如果文件存在则开始执行压缩打包
            if [ -e "${tp}.${yesterday}-20.log" ];then
                if [ -e "${dest_dir}/${gz_file_name}" ];then
                    echo "the ${dest_dir}/${gz_file_name} already exist!" 
                    continue
                else
                    echo "tar zcf ${dest_dir}/${gz_file_name} ${tp}.${yesterday}-*.log"
                    tar zcf ${dest_dir}/${gz_file_name} ${tp}.${yesterday}-*.log
                fi
            fi
            # 删除90天以前的文件
            old_month=$(date -d '-32 day' +%Y%m)
            old_day=$(date -d '-32 day' +%Y-%m-%d)
            old_source_file="${source_base_dir}/${dir}/${ip_dir}/${old_month}/${tp}/${tp}.${old_day}-*.log"  
            old_dest_file="${dest_base_dir}/${dir}/${ip_dir}/${old_month}/${tp}/${ip_dir}_${tp}.${old_day}.tgz"
            if ls ${old_source_file} &> /dev/null; then
                echo "delete old regular file ${old_source_file}"
                rm -rf ${old_source_file}
            else
                echo "delete old regular file ${old_source_file}"
                echo "the ${old_source_file} is not exist."
            fi
            if [ -e ${old_dest_file} ];then
                echo "delete old gz file ${old_dest_file}"
                rm -rf ${old_dest_file}
 
            else
                echo "delete old gz file ${old_dest_file}"
                echo "the ${old_dest_file} is not exist."
            fi
            echo "--------------------------------"
        done
    done
done
#
#done
#/data4/logs/civp_logs/log4j2logs/201706/global
# 上传文件至 ftp 
#for i in {2..100};do
#
#    month=$(date -d "-${i} day" +%Y%m)
#    yesterday=$(date -d "-${i} day" +%Y-%m-%d)
#    if [ ${yesterday} == "2017-08-22" ];then
#        break
#    fi

for dir in ${log_dirs[@]};do
    for ip_dir in ${ip_list[@]};do
        for tp in ${log_type[@]};do
            dest_dir=${dest_base_dir}/${dir}/${ip_dir}/${month}/${tp}
            echo "dest_dir is :${dest_dir}"
            if [ -d "${dest_dir}" ];then
                cd ${dest_dir}/
            else
                continue
            fi
            gz_file_name="${ip_dir}_${tp}.${yesterday}.tgz"
            if [ -e "${gz_file_name}" ];then
                 echo "put ${dir} ${gz_file_name} to ${HOST} ftp."
                /usr/bin/lftp ${USER}:${PASS}@${HOST} << EOF
cd yzftp/${dir%s}/${ip_dir}
#ls
#set xfer:clobber on
put ${gz_file_name}
EOF
                 echo "================================"

            fi
        done
    done
done
#done
