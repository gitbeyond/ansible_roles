#!/bin/bash
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/hdfs/bin

table_txt=/home/hdfs/hive_table/table.txt
export_dir=/tmp/hive_export
log_dir=log
dt=$(date +%Y%m%d_%H%M%S)

[ -d ${log_dir} ] || mkdir ${log_dir}
[ -d history ] || mkdir history

[ -e export_done.txt ] && mv export_done.txt ./history/export_done_${dt}.txt
[ -e export_err.txt ] && mv export_err.txt ./history/export_err_${dt}.txt


grep -E -v "^#|^$" ${table_txt} | while read table;do
    echo "hive -e \"export table ${table} to '${export_dir}/${table}';\""
    #eval $(echo "hive -e \"export table ${table} to '${export_dir}/${table}';\"")
    hive -e "export table ${table} to '${export_dir}/${table}';" 2> ./${log_dir}/export_${table}_err.log 1> ./${log_dir}/export_${table}_right.log
    #sentence="\"export table ${table} to \'${export_dir}/${table}\';\""
    #hive -e ${sentence}
    #echo \"export table ${table} to '${export_dir}/${table}';\"
    hive_e_stat=$?
    if [ ${hive_e_stat} == 0 ];then
        echo ${table} >> export_done.txt
    else
        echo ${table} >> export_err.txt
    fi

done

