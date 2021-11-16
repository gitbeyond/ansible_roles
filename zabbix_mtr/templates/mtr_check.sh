#!/bin/bash
export PATH={{ansible_env['PATH']}}

log_dir=/tmp
dt1=$(/bin/date +%F_%H%M)
mtr_bin=/data/apps/opt/mtr/sbin/mtr

mtr_check(){
    #local log_file=$3
    local mtr_host=${1}
    local mtr_type=${2}
    local mtr_port=$3
    if [ ${mtr_type} == "icmp" ];then
        ${mtr_bin} -4 -n -c 1 -r -b -w -C ${mtr_host} > ${log_dir}/.${mtr_host}_${mtr_type}.out_tmp
            /bin/mv ${log_dir}/.${mtr_host}_${mtr_type}.out_tmp ${log_dir}/.${mtr_host}_${mtr_type}.out
    else
        ${mtr_bin} -4 -n --tcp --port ${mtr_port} -r -b -w -C ${mtr_host} > ${log_dir}/.${mtr_host}_${mtr_port}_${mtr_type}.out_tmp
            /bin/mv ${log_dir}/.${mtr_host}_${mtr_port}_${mtr_type}.out_tmp ${log_dir}/.${mtr_host}_${mtr_port}_${mtr_type}.out
    fi
}


IFSBAK=${IFS}
export IFS=,
grep -E -v "^#|^$" {{ zabbix_script_dir }}/mtr_hosts.txt | while read desc host type port;do
    mtr_check ${host} ${type} ${port} &
done


