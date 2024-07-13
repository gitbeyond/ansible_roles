#!/bin/bash
export PATH={{ansible_env['PATH']}}

log_dir={{mtr_out_dir}}
dt1=$(/bin/date +%F_%H%M)
mtr_bin={{mtr_bin}}
zabbix_agent_script_dir={{zabbix_agent_script_dir}}

{%raw%}
mtr_check(){
    #local log_file=$3
    local mtr_host=${1}
    local mtr_type=${2}
    local mtr_port=$3
    local tmp_log="" host_log=""
    if [ ${mtr_type} == "icmp" ];then
        tmp_log=${log_dir}/.${mtr_host}_${mtr_type}.out_tmp
        host_log=${log_dir}/${mtr_host}_${mtr_type}.out
        ${mtr_bin} -4 -n -c 10 -i 1 -G 1 -r -b -w -C ${mtr_host} > ${tmp_log}
    else
        tmp_log=${log_dir}/.${mtr_host}_${mtr_port}_${mtr_type}.out_tmp
        host_log=${log_dir}/${mtr_host}_${mtr_port}_${mtr_type}.out
        ${mtr_bin} -4 -n --tcp --port ${mtr_port} -r -b -w -C ${mtr_host} > ${tmp_log}
    fi
    /bin/mv ${tmp_log} ${host_log}
}


IFSBAK=${IFS}
export IFS=,
grep -E -v "^#|^$" ${zabbix_agent_script_dir}/mtr_hosts.txt | while read desc host type port;do
    mtr_check ${host} ${type} ${port} &
done
{%endraw%}
