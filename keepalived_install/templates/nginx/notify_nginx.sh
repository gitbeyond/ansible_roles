#!/bin/bash
export PATH={{ansible_env.PATH}}

master_script={{keepalived_conf_dir}}/nginx_master.sh
backup_script={{keepalived_conf_dir}}/nginx_backup.sh
fault_script={{keepalived_conf_dir}}/nginx_fault.sh
stop_script={{keepalived_conf_dir}}/nginx_fault.sh

exec_script(){
    for((i=0;i<${retry_count};i++));do
        /bin/bash $1
        if [[ $? == 0 ]];then
            i=${retry_count}
        fi
    done
}

if [[ $# -lt 1 ]];then
    exit 5
fi
retry_count=3
notify_state=$1

case ${notify_state} in
    "[master]"|"master")
        exec_script ${master_script}
    ;;
    "[backup]"|"backup")
        exec_script ${backup_script}
    ;;
    "[fault]"|"fault")
        exec_script ${fault_script}
    ;;
    "[stop]"|"stop")
        exec_script ${fault_script}
    ;;
    *)
        exit 6
    ;;
esac

