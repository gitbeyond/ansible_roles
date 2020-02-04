#!/bin/bash

export PATH={{ansible_env["PATH"]}}
BK_USER={{mysql_backup_user}}
BK_PASS="{{mysql_backup_pass}}"
IP="{{ansible_default_ipv4.address}}"
mail_script=$(cd $(dirname $0) && pwd)/send_mail.py
project_name="${IP} binlog backup"
mysql_sock={{mysql_sock}}
mysql_host=localhost
mysql_vip={{mysql_vip}}
mysql_backup_host={{mysql_backup_host}}
mysql_basedir={{mysql_basedir.msg}}
mysql_datadir={{mysql_datadir.msg}}
REMOT_HOST={{mysql_backup_remote_host}}
BackPath={{mysql_backup_path}}
mysql_backup_remote_user={{mysql_backup_remote_user}}
Remote_BackPath={{mysql_backup_remote_path}}/$IP


{%raw%}
day_dt=$(date +%F_%H-%M-%S)
#BackPath=/data/apps/data/mysqlbackup
OUT_FILE=/tmp/`basename $0`.out
check_vip(){
    if [ -n "${mysql_vip}" ];then
        # vip 不为空, 判断 vip 是否存在于本机
        if ip a |grep "${mysql_vip}" &> /dev/null;then
            echo "the host isn't backup host."
            exit 5
        else
            echo "continue"
        fi 
    else
        # vip 为空的，
        vip_text="VIP is none." 
        echo "${vip_text}"
    fi
}
check_backup_host(){
    if [ -n "${mysql_backup_host}" ];then
        # ${mysql_backup_host} 不为空, 判断 ip 是否是本机
        if ip a |grep "${mysql_backup_host}" &> /dev/null;then
            echo "continue"
        else
            echo "the host isn't backup host."
            exit 5
        fi 
    else
        # vip 为空的，
        vip_text="mysql_backup_host is none." 
        echo "${vip_text}"
    fi
}

check_vip
check_backup_host
# 判断备份目录所在的磁盘空间是否充裕
datadir_size=$(du -s ${mysql_datadir} |awk '{print $1}')
# datadir 的大小再加上 100G
datadir_size=$[datadir_size+104857600]
BackPath_dev_num=$(stat -c '%d' ${BackPath})
all_mount_point=($(df -l |awk '{print $NF}' | tail -n +2))
for p in ${all_mount_point[@]};do
    p_dev_num=$(stat -c '%d' ${p})
    if [ ${BackPath_dev_num} == ${p_dev_num} ];then
        mount_dev=${p}
        break
    else
        continue
    fi
done
dev_free_space=$(df -l ${mount_dev} | tail -n 1 |awk '{print $4}')
if [ ${datadir_size} -lt ${dev_free_space} ];then
    echo "${mount_dev} space is ok."
else
    echo "the ${mount_dev} free space is unavailable."
    mail_text="`date` ${project_name} mysql backup failed. the ${mount_dev} free space is unavailable."
    echo "backup failed." >> $OUT_FILE
    python ${mail_script} "${project_name}" "${mail_text}"
    exit 6
fi

#day_dt=$(date +%F)
#Remote_BackPath=/data2/mysqlbackup/$IP
mysql_opt="--user=${BK_USER} --password=${BK_PASS} --socket=${mysql_sock} --host=${mysql_host}"

mysql_cmd=${mysql_basedir}/bin/mysql
mysqlbinlog_cmd=${mysql_basedir}/bin/mysqlbinlog
logbin_index=$($mysql_cmd ${mysql_opt} -se "select @@log_bin_index;" 2> /dev/null)
logbin_basename=$(head -n 1 ${logbin_index})
# 判断是否开启了二进制日志
if [ ! -z "${logbin_basename}" ];then
    logbin_name=$(basename ${logbin_basename} | awk -F '.' '{print $1}')
    echo "`date +'%F %T'` the binlog name is $logbin_name"
else
    echo "`date +'%F %T'` binary log is not enabled! exit!"
    exit 0
fi

# 确定二进制日志备份的起点
last_backup_data=$(ls -ad1 $BackPath/*/ | tail -n 1)
last_backup_data=${last_backup_data%/}
# 检查是否有 xtrabackup_binlog_info 文件,没有从上一个二进制日志的备份中获取
if [ -e ${last_backup_data}/xtrabackup_binlog_info ];then
    binlog_begin_file=$(head -n 1 ${last_backup_data}/xtrabackup_binlog_info | awk '{print $1}')
    binlog_begin_offset=$(head -n 1 ${last_backup_data}/xtrabackup_binlog_info | awk '{print $2}')
else
    binlog_begin_file=$(ls -1 ${last_backup_data} |grep -v binlog_backup_info |grep "${logbin_name}.*[0-9]$" | tail -n 1)
    if [ -n "${binlog_begin_file}" ];then
        binlog_begin_file_num=$(find ${BackPath} -name "${binlog_begin_file}" |wc -l)
        if [ ${binlog_begin_file_num} -eq 1 ];then
            binlog_begin_offset=$(stat -c %s ${last_backup_data}/${binlog_begin_file})    
        else
            binlog_begin_offset=$(awk '/^stop-position/{print $2}' ${last_backup_data}/binlog_backup_info)
        fi
        #binlog_begin_offset=$(find ${BackPath} -name "${binlog_begin_file}" -exec stat -c %s {} \; | awk 'BEGIN{a=0}{a+=$1}END{print a}')
        #binlog_begin_offset=$(awk '/^stop-position/{print $2}' ${last_backup_data}/binlog_backup_info)
    else
        mail_text="`date` ${IP} binlog_begin_file is none."
    fi
fi

# 开始执行备份
if [ -n "${binlog_begin_file}" ] && [ -n "${binlog_begin_offset}" ];then
    binlog_end_offset=$($mysql_cmd ${mysql_opt} -se "show master status\G" 2> /dev/null |awk '/Position/{print $2}')
    [ -e ${BackPath}/${day_dt} ] || mkdir -p ${BackPath}/${day_dt}
    ${mysqlbinlog_cmd} --no-defaults ${mysql_opt} --raw \
      --read-from-remote-server --to-last-log \
      --start-position=${binlog_begin_offset} \
      ${binlog_begin_file} \
      --result-file=${BackPath}/${day_dt}/
      #--stop-position=${binlog_end_offset} \
    binlog_backup_stat=$?
    echo "${day_dt}
${mysqlbinlog_cmd} --no-defaults ${mysql_opt} --raw --read-from-remote-server --to-last-log --start-position=${binlog_begin_offset} ${binlog_begin_file} --result-file=${BackPath}/${day_dt}/
start-position: ${binlog_begin_offset}
stop-position: ${binlog_end_offset}
binlog_backup_stat: ${binlog_backup_stat}" >> ${BackPath}/${day_dt}/binlog_backup_info

    if [ ${binlog_backup_stat} == 0 ];then
        mail_text="${mail_text}.\n ${day_dt} binlog backup successful. 
start-position: ${binlog_begin_offset}.
stop-position: ${binlog_end_offset}.
"
    else
        mail_text="${mail_text}.\n ${day_dt} binlog backup failed. "
    fi
else
        mail_text="`date` ${IP} binlog_begin_file is none.
binlog_begin_file: ${binlog_begin_file}.
binlog_begin_offset: ${binlog_begin_offset}.
binlog backup failed."
    python ${mail_script} "${project_name}" "${mail_text}"
    exit 5
fi

#if [ ${binlog_backup_stat} == 0 ];then
#    binlog_backup_file=${BackPath}/${day_dt}
#else
#    
#fi
cd ${BackPath}
if ssh ${mysql_backup_remote_user}@${REMOT_HOST} [ ! -e ${Remote_BackPath} ];then
    ssh ${mysql_backup_remote_user}@${REMOT_HOST} mkdir ${Remote_BackPath}
fi
scp -r ${BackPath}/${day_dt} ${mysql_backup_remote_user}@${REMOT_HOST}:${Remote_BackPath}/
scp_stat=$?

if [ ${scp_stat} == 0 ];then
    scp_text="send mysql binlog backup file successed."
else
    scp_text="send mysql binlog backup file failed."
fi
mail_text="${mail_text}
${scp_text}
`stat ${BackPath}/${day_dt}`
`ls -l ${BackPath}/${day_dt}`"

python ${mail_script} "${project_name}" "${mail_text}"

{%endraw%}
