#!/bin/bash
# edit date: 2017/6/29
#
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

log_base_dir=/data4/ftp/vuserdir/yzftp
#log_dirs=( civp_log service_log )
log_dirs=( civp_log )
log_type=( global global_api_inner global_api_outside )
ip_list=( 9.45 9.46 9.52 9.53 9.112 9.113)
#ip_list=( 9.52 )

dest_dir=/data1/logs

month=$(date -d '-8 day' +%Y%m)
yesterday=$(date -d '-8 day' +%Y-%m-%d)

su_hdfs="/bin/su - hdfs -c"
succ_count=0
file_size=0

delete_old() {
    local files=$(ls |grep  "^[0-9]$")
    for i in ${files};do
        if [[ $i < ${1} ]];then
            echo "delete $i"
        fi
    done
}
echo "`date`#################################"
# 以 civp_log 和 service_log 这两个不同服务分类
for dir in ${log_dirs[@]};do
    # 以 ip 进行循环，现在的 ip 有 9.45, 9.46, 9.52, 9.53
    for ip_dir in ${ip_list[@]};do
        echo "==================================="
        echo "cd ${log_base_dir}/${dir}/${ip_dir}"
        cd ${log_base_dir}/${dir}/${ip_dir}
        # 在目录下根据 日志类型来获取文件
        for tp in ${log_type[@]};do
            # 获取最近的一个文件
            if ls ${ip_dir}_${tp}.*.tgz &> /dev/null; then
                last_file=$(ls ${ip_dir}_${tp}.*.tgz | head -n 1)
                # 判断文件是否传输完毕, lsof 成功代表文件正在被其他进程使用
                if lsof ${last_file} &> /dev/null;then
                    echo "the file ${last_file} is sending..."
                    continue
                else
                    # 根据最近的文件获取月份
                    file_month=$(date -d $(echo ${last_file} |awk -F'.' '{print $3}') +%Y%m)
        
                    # 根据最近的文件获取哪一天
                    file_day=$(date -d $(echo ${last_file} |awk -F'.' '{print $3}') +%d)
                fi
            else
                echo "no ${ip_dir}_${tp}.*.tgz files, Execute next."
                continue
            fi

            dest_file_dir=${dest_dir}/${dir}/${ip_dir}/${file_month}/${tp}/${file_day}
            # 在解压log目录内创建以天为单位的目录
            [ -e ${dest_file_dir} ] || mkdir -p ${dest_file_dir}

            # 解压日志文件到 各自相关的目录下
            #echo "tar xf ${ip_dir}_${tp}.${yesterday}.tgz -C ${dest_dir}/${dir}/${ip_dir}/${file_month}/${tp}/${file_day}/"
            echo "tar xf ${last_file} -C ${dest_file_dir}/"
            tar xf ${last_file} -C ${dest_file_dir}/
            # 计算文件大小
            if [ $? == 0 ];then
                the_size=$(du -s ${dest_file_dir} | awk '{print $1}')
                file_size=$[file_size+the_size]
            else
                echo "${last_file} unzip failed."            
            fi
            # 解压成功的话，就把当前文件移动到以 日期天命名的目录内，方便删除
            if [ $? == 0 ];then
                [ -e ${file_day} ] || mkdir ${file_day}
                mv ${last_file} ${file_day}
                old_dir=$(date -d '-10 day' +%d)
                echo "delete old_dir ${old_dir}"
                [ -e ${old_dir} ] && rm -rf ${old_dir}
            fi
            # 得到 hdfs 目录上的类型名，civp_log 与 civp(hdfs 上的名称) 相对 
            echo "chown -R hdfs.hdfs ${dest_dir}"
            chown -R hdfs.hdfs ${dest_dir}
            hdfs_tp_dir=${dir%_*}

            # 检测hdfs 上的目录是否存在，不存在则创建
            put_file_dir=${dest_dir}/${dir}/${ip_dir}/${file_month}/${tp}/${file_day}
            hdfs_file_dir=/log/${hdfs_tp_dir}/${ip_dir}/${file_month}/${tp}
            echo "${su_hdfs} \"hdfs dfs -test -e ${hdfs_file_dir}\"" || echo "hdfs dfs -mkdir -p ${hdfs_file_dir}"
            ${su_hdfs} "hdfs dfs -test -e ${hdfs_file_dir}" || ${su_hdfs} "hdfs dfs -mkdir -p ${hdfs_file_dir}"

    # 上传解压后的日志文件
            echo "hdfs dfs -put ${put_file_dir}/*.log ${hdfs_file_dir}/"
            ${su_hdfs} "hdfs dfs -put -f ${put_file_dir}/*.log ${hdfs_file_dir}/"
            [ $? = 0 ] && succ_count=$[succ_count+1]

    # 删除10天以前的文件，这里有问题,单纯以天来删除的话，会忽略掉月份
            old_month=$(date -d '-10 day' +%Y%m)
            old_regular_file=${dest_dir}/${dir}/${ip_dir}/${old_month}/${tp}/${old_dir}
            echo "delete regular old log dir ${old_regular_file}"
            [ -e "${old_regular_file}" ] && rm -rf ${old_regular_file}
            echo "------------------------------"
        done
    done
done
echo "`date`#################################"

# send mail
mail_text="`date` civp log put complate.
total 20.
total size $(echo "scale=3;${file_size}/1024" |bc)M.
succeed ${succ_count}.
"
echo "$(echo "scale=3;${file_size}/1024" |bc)M"
echo "${succ_count}"

python /root/script/civp_email.py "${mail_text}"
