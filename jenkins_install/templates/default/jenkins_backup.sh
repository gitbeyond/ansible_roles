#!/bin/bash
set -uo pipefail
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
mail_str=""
mail_from_addr=""
mail_from_pass=""
mail_smtp_addr=""
mail_to_addr=""
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


mylog(){
    local level=""
    if [ ${#} -gt 1 ];then
        level="${1}"
        shift
    else
        level="info"
    fi
    # BASH_LINENO[0] 代表引用此函数的函数的定义行号，BASH_LINENO[1]代表调用“引用此函数”的函数的调用行号
    # LINENO则是本函数定义的行号
    echo "$(date +'%F %T.%N') func_name:${FUNCNAME[1]} line:${BASH_LINENO[0]} call_line:${BASH_LINENO[1]} level:${level} ${@}"
}

# 本地备份
jenkins_backup(){
    [ -e ${jenkins_backup_dir} ] || mkdir -p ${jenkins_backup_dir}
    tar ${tar_opts}
    # local file_size_info=""
    # file_size_info=$(du -sh ${jenkins_backup_file_full_path})
    # mail_str="${mail_str} ${file_size_info}"
}
# 复制到远端，根据实际情况做出变动
cp_backup_to_remote(){
    :
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

# 实际使用时，需要更改
send_mail(){
    # -S smtp-use-starttls \
    local mail_title="${1}" mail_str="${2}" 
    # 如果希望发送html的邮件，为title添加Content-Type
    mail_title="${mail_title}
Content-Type: text/html"
    echo "${mail_str}" | mailx -v \
        -s "${mail_title}" \
        -r "dev-jenkins<${mail_from_addr}>" \
        -S smtp="${mail_smtp_addr}" \
        -S smtp-auth=login \
        -S smtp-auth-user="${mail_from_addr}" \
        -S smtp-auth-password="${mail_from_pass}" \
        -S ssl-verify=ignore ${mail_to_addr} 2> /dev/null
}

main(){
    check_lock
    jenkins_backup
    local backup_stat=$?
    if [ ${backup_stat} != 0 ];then
        echo "$(date) The jenkins_backup function is failed."
    fi
    delete_old_backup_file
}
main
