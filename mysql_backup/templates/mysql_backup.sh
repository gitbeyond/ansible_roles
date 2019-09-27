#!/bin/bash
export PATH={{ansible_env["PATH"]}}
BK_USER={{mysql_backup_user}}
BK_PASS="{{mysql_backup_pass}}"
IP="{{ansible_default_ipv4.address}}"
mail_script=$(cd $(dirname $0) && pwd)/send_mail.py
project_name="{{group_names[-1]}} ${IP}"
mysql_sock={{mysql_sock}}
mysql_vip={{mysql_vip}}
mysql_basedir={{mysql_basedir.msg}}
mysql_datadir={{mysql_datadir.msg}}
backup_num={{mysql_backup_num}}

{%raw%}
day_dt=$(date +%F)
REMOT_HOST="172.16.8.120"
BackPath=/data/apps/data/mysqlbackup
OUT_FILE=/tmp/`basename $0`.out
Remote_BackPath=/data2/mysqlbackup/$IP
# 如果 vip 是空的，那么就往下继续执行
# 如果不为空，则判断本机是否有 vip
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
    vip_text="VIP isn't on the host." 
fi

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
    python ${mail_script} "${mail_text}"
    exit 6
fi

# 确定配置文件
if [[ ${mysql_basedir} == /data/apps/opt/mysql* ]] || [[ ${mysql_basedir} == /data1/apps/opt/mysql* ]];then
    mysql_conf=/data1/apps/config/mysql/my.cnf
elif [[ ${mysql_basedir} == /usr* ]];then
    mysql_conf=/etc/my.cnf
else
    if [ -e /etc/my.cnf ];then
        mysql_conf=/etc/my.cnf
    else
        mysql_conf=${mysql_basedir}/my.cnf
    fi
fi
# 开始备份
echo -e "--------------------------------\n`date` start mysql backup!" >> $OUT_FILE
[ -d ${BackPath} ] || mkdir -p ${BackPath}

innobackupex --defaults-file=${mysql_conf} --user=${BK_USER} --password="${BK_PASS}" --socket=${mysql_sock} ${BackPath} 
backup_stat=$?
#backup_stat=0

if [ ${backup_stat} == 0 ];then
    backup_file=$(ls ${BackPath}/${day_dt}* -d |tail -n 1)
else
    mail_text="`date` ${project_name} mysql backup failed."
    echo "backup failed." >> $OUT_FILE
    python ${mail_script} "${mail_text}"
    exit 5
fi
cd ${BackPath}
if ssh ${REMOT_HOST} [ ! -e ${Remote_BackPath} ];then
    ssh ${REMOT_HOST} mkdir ${Remote_BackPath}
fi
scp -r ${backup_file} ${REMOT_HOST}:${Remote_BackPath}/
scp_stat=$?
#scp_stat=0

if [ ${scp_stat} == 0 ];then
    scp_text="send mysql backup file successed."
else
    scp_text="send mysql backup file failed."
fi

# delete old file
cd ${BackPath}
echo "rm -rf ${old_file}"
old_file=$(ls -c1 |tail -n +2)
rm -rf ${old_file}
# 删除远程备份目录的旧的备份

remote_old_file=$(ssh ${REMOT_HOST} "cd ${Remote_BackPath}; ls -c1 |tail -n +$[backup_num+1]")
echo ${remote_old_file}
ssh -T ${REMOT_HOST} << EOF
   cd ${Remote_BackPath}
   #rm -rf ${remote_old_file} 
EOF

mail_text="
`date` ${project_name} mysql database backup successed.
backup file is ${backup_file}.
backup file info: 
`stat ${backup_file}`.
backup file size: `du -sh ${backup_file}`.
${scp_text}
the VIP is: ${mysql_vip}. ${vip_text}.
deleted ${old_file}.
deleted ${REMOT_HOST}:${remote_old_file}
"
python ${mail_script} "${mail_text}"
{%endraw%}
