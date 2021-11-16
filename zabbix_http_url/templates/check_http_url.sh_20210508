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
#link "http://172.16.9.45:8070/civp/getview/testExceptionCatch/test1" "civp_web.log"
link "http://{{ansible_default_ipv4['address']}}:8070/civp/getview/restdemo/execute" "civp_web.log"

# 下面的一些数据源无法使用 zabbix 自带的 key 进行监控，所以在这里受用了 curl 的方式
urls=(
"http://api.bd.ctyun.cn:18080"
)
data_source=($(grep -E -v "^#|^$" {{ zabbix_script_dir }}/http_url.txt | awk '{print $2}'))
#echo ${data_source[@]}
for addr in ${data_source[@]};do
    addr_log=${addr#*//}
    addr_log=${addr_log%%/*}
    link "${addr}" "${addr_log}.log" &
done

