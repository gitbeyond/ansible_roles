#!/bin/bash
set -euo pipefail
export LANG=en_US.UTF-8
# jenkins 数据目录
jenkins_data_dir='{{jenkins_data_dir}}'
jenkins_data_dir_name=$(dirname ${jenkins_data_dir})
jenkins_data_base_name=$(basename ${jenkins_data_dir})
# 一个标识符，如 dev-jenkins
jenkins_project_name="{{jenkins_project_name}}"
# 备份目录
jenkins_backup_dir="{{jenkins_backup_dir}}"
day_dt=$(date +'%Y%m%d')
jenkins_backup_file="${jenkins_project_name}_${day_dt}.tar.gz"
jenkins_backup_file_full_path="${jenkins_backup_dir}/${jenkins_backup_file}"
keep_file_num=5
tar_opts="{{jenkins_tar_opts}} ${jenkins_backup_file_full_path} -C ${jenkins_data_dir_name} ${jenkins_data_base_name}"

lock_file="${jenkins_backup_dir}/.jenkins_backup.lock"

check_lock(){
    exec 3<> ${lock_file}
    if flock -n 3;then
        #echo "get ${lock_file} lock file."
        :
    else
        echo "get lock file failed. now exit."
        exit 5
    fi
}

jenkins_backup(){
    [ -e ${jenkins_backup_dir} ] || mkdir -p ${jenkins_backup_dir}
    tar "${tar_opts}"
}
# 删除历史文件
delete_old_backup_file(){
    local file_num=$((keep_file_num+1))
    local old_files=""
    old_files=$(ls -t1 ${jenkins_backup_dir} | tail -n +${file_num})
    cd ${jenkins_backup_dir}
    for i in ${old_files};do
        echo "$(date) delete ${jenkins_backup_dir}/${i}"
        [ -e "${i}" ] && /bin/rm -f "${i}"
    done
}

main(){
    check_lock
    jenkins_backup
    delete_old_backup_file
}
main
