#!/bin/bash
set -e

lock_file={{etcd_var_dir}}/etcd_backup.lock
exec 3<> ${lock_file}

if flock -n 3;then
    #echo "get ${lock_file} lock file."
    :
else
    echo "get lock file failed. now exit."
    exit 5
fi

exec >> {{etcd_log_dir}}/backup_etcd.log

Date=`date +%Y-%m-%d-%H-%M`
EtcdEndpoints="https://localhost:2379"
EtcdCmd="{{etcd_base_dir}}/etcdctl --cacert={{etcd_conf_dir}}/ssl/etcd-root-ca.pem --cert={{etcd_conf_dir}}/ssl/etcd-client-ca.pem --key={{etcd_conf_dir}}/ssl/etcd-client-ca-key.pem"
BackupDir="{{etcd_backup_dir}}"
BackupFile="snapshot.db.$Date"
localBackupNum=10
remoteBackupNum=100

local_ip={{ansible_default_ipv4.address}}
# remote
remote_host={{backup_remote_host}}
remote_user={{backup_remote_user}}
remote_dir={{backup_remote_dir}}/${local_ip}
scp_lock_file=/tmp/.$(basename ${0/.*/.lock})


cp_tar_file_to_remote(){
    if [ -n "${1}" ];then
        :
    else
        echo 'args is empty.'
        return 2
    fi
    local tar_file=$1
    if grep "${tar_file}" ${scp_lock_file};then
        echo "the ${tar_file} already scp complete."
        return 0
    else
        :
    fi
    local project_name=$(basename $(cd $(dirname ${tar_file}) && pwd))
    local project_remote_dir=${remote_dir}/${project_name}
    ssh ${remote_user}@${remote_host} mkdir -p ${project_remote_dir}
    scp ${tar_file} ${remote_user}@${remote_host}:${project_remote_dir}/
    if [ $? == 0 ];then
        echo "${tar_file}" > ${scp_lock_file}
        echo "scp ${tar_file} complate."
        return 0
    else
        echo "scp ${tar_file} failed."
        return 1
    fi
}

remote_delete_oldfile() {
    local project_remote_dir=$1
    local backup_num=10
    local remote_old_file=$(ssh ${remote_host} "cd ${project_remote_dir}; ls -c1 |tail -n +$[backup_num+1]")
    remote_old_file=$(echo ${remote_old_file} | tr "\n" " ")
    ssh -T ${remote_host} << EOF
cd ${remote_dir}
rm -rf ${remote_old_file} 
EOF
}

test_dir_or_pdir(){
    local backup_dir=$1
    if [ -n "${1}" ];then
        :
    else
        echo 'args is empty.'
        return 2
    fi
    if [ -d ${backup_dir} ];then
        :
    else
        backup_dir=$(dirname ${backup_dir})
        if [ -d ${backup_dir} ];then
            :
        else
            echo "${backup_dir} isn't exist."
            return 1
        fi
    fi
    echo ${backup_dir}
}


keep_num_delete() {
    local backup_dir=$1
    backup_dir=$(test_dir_or_pdir ${backup_dir})

    if [ -n "$2" ];then
        local keep_day=$2
    else
        local keep_day=${localBackupNum}
    fi
    old_file=$(ls -cr1 ${backup_dir} |head -n -${keep_day})
    echo "rm -rf ${old_file}"
    cd ${backup_dir}
    rm -rf ${old_file}
    cd -
}



[ -d ${BackupDir} ] || mkdir -p ${BackupDir}
echo "`date` backup etcd..."

export ETCDCTL_API=3
$EtcdCmd --endpoints $EtcdEndpoints snapshot save  $BackupDir/$BackupFile
etcd_backup_stat=$?

echo  "`date` backup done!"

if [ ${etcd_backup_stat} != 0 ];then
    echo "${Date} etcd backup failed!"
    mail_text="${Date} etcd backup failed!"
    exit 1
fi


cp_tar_file_to_remote $BackupDir/$BackupFile
cp_file_stat=$?
if [ ${cp_file_stat} != 0 ];then
    echo "${Date} etcd cp to remote failed."
    mail_text="${Date} etcd cp to remote failed."
    exit 2
fi

keep_num_delete ${BackupDir}
