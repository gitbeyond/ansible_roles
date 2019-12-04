#!/bin/bash
export PATH={{ansible_env["PATH"]}}

dt_day=$(date +%Y%m%d)
source_dirs=(
{%for dir in local_source_dirs%}
{{dir}}
{%endfor%}
)
local_ip={{ansible_default_ipv4.address}}
#target_dir=/data/apps/data/backup/jenkins
target_parent_dir={{local_target_parent_dir}}
# remote host
remote_host={{backup_remote_host}}
remote_user={{backup_remote_user}}
remote_dir={{backup_remote_dir}}/${local_ip}
scp_lock_file=/tmp/.$(basename ${0/.*/.lock})

# email
mail_script=$(cd $(dirname $0) && pwd)/send_mail.py
mail_text=""

exclude_files=(
{%for dir in local_exclude_files%}
"{{dir}}"
{%endfor%}
)
{%raw%}
get_exclude_file() {
    if [ -n "${1}" ];then
        :
    else
        echo 'args is empty.'
        return 2
    fi
    fn_str=""
    for fn in ${1};do
        fn_str="${fn_str} --exclude ${fn}"
    done
    echo "${fn_str}"
}

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
find_f_delete() {
    if [ -n "${1}" ];then
        :
    else
        echo 'args is empty.'
        return 2
    fi
    local backup_dir=$1
    backup_dir=$(test_dir_or_pdir ${backup_dir})

    if [ -n "$2" ];then
        local keep_day=$2
    else
        local keep_day=10
    fi
    old_file=$(find ${backup_dir} -maxdepth 1 -type f -mtime +${keep_day})
    echo "rm -rf ${old_file}"
}

keep_num_delete() {
    backup_dir=$(test_dir_or_pdir ${backup_dir})
    
    if [ -n "$2" ];then
        local keep_day=$2
    else
        local keep_day=10
    fi
    old_file=$(ls -cr1 ${backup_dir} |head -n -10)
    echo "rm -rf ${old_file}"
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



for ((idx=0;idx<${#source_dirs[@]};idx++));do
    echo ${idx}
    echo ${source_dirs[${idx}]}
    echo ${exclude_files[${idx}]}
    source_dir=${source_dirs[${idx}]}
    source_parent_dir=$(dirname ${source_dir})
    source_base_dir=$(basename ${source_dir})
    target_dir="${target_parent_dir}/${source_base_dir}"
    [ -e ${target_dir} ] || mkdir -p ${target_dir}
    target_file=${source_base_dir}_${dt_day}.tar.gz

    #a=$(for exclude_file in ${exclude_files[${idx}]};do
    #    echo "--exclude ${exclude_file}"
    #done)
    exclude_str=$(get_exclude_file "${exclude_files[${idx}]}")
    tar_cmd="tar --use-compress-program=pigz -cvf ${target_dir}/${target_file} -C ${source_parent_dir} ${exclude_str} ${source_base_dir}"
    if [ -e ${target_dir}/${target_file} ];then
        echo "the ${target_dir}/${target_file} already exist."
    else
        echo "${tar_cmd}"
        ${tar_cmd}
        tar_stat=$?
    fi

    if [ "${tar_stat}" == 0 ];then     
        scp_ret=$(cp_tar_file_to_remote ${target_dir}/${target_file})
        scp_stat=$?
        if [ ${scp_stat} == 0 ];then
            :
        else
            echo "${scp_ret}"
            mail_text="${mail_text}. ${scp_ret}"
        fi
    else
        echo "tar ${target_dir}/${target_file} packat failed."
        mail_text="${mail_text}. tar ${target_dir}/${target_file} packat failed."
    fi
    
    if [ ${#mail_text} -gt 5 ];then
        project_name="backup_${source_dir}"
        python ${mail_script} "${project_name}" "${mail_text}"
    fi
    echo "find_f_delete ${target_dir}"
    find_f_delete ${target_dir}
    echo "remote_delete_oldfile ${remote_dir}/${source_base_dir}"
    remote_delete_oldfile ${remote_dir}/${source_base_dir}
done

#which pigz

#--use-compress-program=pigz
#tar_cmd="tar  zcf ${target_dir}/${target_file} -C ${source_parent_dir} ${exclude_str} ${source_base_dir}"
#tar_cmd="tar --use-compress-program=pigz -cvf ${target_dir}/${target_file} -C ${source_parent_dir} ${exclude_str} ${source_base_dir}"
#if [ -e ${target_dir}/${target_file} ];then
#    echo "the ${target_dir}/${target_file} already exist."
#
#else
#    echo ${tar_cmd}
#    ${tar_cmd}
#fi

{%endraw%}
