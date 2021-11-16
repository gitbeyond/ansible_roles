#!/bin/bash
export PATH={{ansible_env['PATH']}}
export NSS_SDB_USE_CACHE=no

log_dir={{curl_out_dir}}
dt1=$(/bin/date +%F_%H%M)

link() {
    local log_file=$2 
    
    local data=$(curl -k --connect-timeout 10 -m 10 -o /dev/null -s -w %{http_code}:%{time_connect}:%{time_starttransfer}:%{time_total}:%{time_namelookup} $1)
    [ -e ${log_dir}/${log_file} ] || touch ${log_dir}/${log_file}
    local size=$(/usr/bin/du ${log_dir}/${log_file} | awk '{print $1}')
#    echo $size
    echo "${data}:${dt1}" >> ${log_dir}/${log_file}

    if [ $size -gt 20480 ];then
        mv ${log_dir}/${log_file} ${log_dir}/${log_file}_${dt}
        touch ${log_dir}/${log_file}
    fi
}

#data_source=($(grep -E -v "^#|^$" {{ zabbix_script_dir }}/http_url.txt | awk -F',' '{print $2}'))
IFSBAK=${IFS}
export IFS=,
#echo ${data_source[@]}
#for addr in ${data_source[@]};do
grep -E -v "^#|^$" {{ zabbix_script_dir }}/http_url.txt  | while read desc addr method in ${data_source[@]};do
    addr_log=${addr#*//}
    addr_log=${addr_log%%/*}
    link "${addr}" "${desc}_${addr_log}.log" &
done

