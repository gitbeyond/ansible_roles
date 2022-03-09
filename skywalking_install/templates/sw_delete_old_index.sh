#!/bin/bash
# author: haifengsss@163.com

# 10.0.20.20:9200,10.0.16.87:9200,10.0.16.142:9200
es_master_hosts='{{es_master_hosts}}'
#es_host=172.16.10.9
es_port=9200
es_url="http://${es_host}:${es_port}"
es_index_keep_days=5

es_index_out_file=/tmp/.${es_host}.out
get_all_index(){
    local es_hosts="${es_master_hosts//,/ }"
    # clean the content of file
    > ${es_index_out_file}
    for h in ${es_hosts};do
        local es_url="http://${h}"
        local es_index_out_file=/tmp/.${h}_index.out
        curl -i --connect-timeout 5 ${es_url}/_cat/indices?v > ${es_index_out_file}
        if head -n 1 ${es_index_out_file} |grep "\<200\>" > /dev/null; then
            break
        fi
    done
}

del_index() {
    local index=$1
    if [ -n "${index}" ];then
        curl -s -X DELETE ${es_url}/${index}
        del_stat=$?
        echo ''
        return ${del_stat}
    else
        return 1
    fi
}

del_old_index(){
    for d in $(seq ${es_index_keep_days} 100);do
        dt=$(date -d"${d} day ago" +%s)
        #echo ${dt}
        dt_f1=$(date -d@${dt} +%Y.%m.%d)
        dt_f2=$(date -d@${dt} +%Y%m%d)
        #echo ${dt}
        old_index=$(grep -E "${dt_f1}|${dt_f2}" ${es_index_out_file}|awk '{print $3}')   
        if [ -n "${old_index}" ];then
            for idx in ${old_index};do
                echo "del_index ${idx}"
                del_index ${idx}
            done
        else
            #break
            continue
        fi
    done
}
main(){
    get_all_index
    del_old_index
}
main
