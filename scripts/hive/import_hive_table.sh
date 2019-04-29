#!/bin/bash
export PATH=/usr/lib64/qt-3.3/bin:/data/apps/opt/mysql/bin:/usr/local/jdk1.8.0_111/bin:/usr/local/jdk1.8.0_111/jre/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/hdfs/.local/bin:/home/hdfs/bin

#export_table_file=/home/hdfs/hive_table/export_done.txt
export_table_file=/home/hdfs/hive_table/distcp_log/distcp_done.txt

hdfs_source_dir=hdfs://172.16.8.4:8020/tmp/hive_export
hdfs_target_dir=/tmp/hive_import

dt=$(date +%Y%m%d_%H%M%S)

distcp_log_dir=distcp_log
#distcp_log_file=distcp
import_log_dir=import_log
history_log_dir=history

mkdir -p ./${distcp_log_dir} ./${import_log_dir} ./${history_log_dir}

#[ -e ${distcp_log_dir}/distcp_done.txt ] && mv ${distcp_log_dir}/distcp_done.txt ${history_log_dir}/distcp_done.txt_${dt}
#[ -e ${distcp_log_dir}/distcp_err.txt ] && mv ${distcp_log_dir}/distcp_err.txt ${history_log_dir}/distcp_err.txt_${dt}
#
#[ -e ${import_log_dir}/import_done.txt ] && mv ${import_log_dir}/import_done.txt ${history_log_dir}/import_done.txt_${dt}
#[ -e ${import_log_dir}/import_err.txt ] && mv ${import_log_dir}/import_err.txt ${history_log_dir}/import_err.txt_${dt}


#for log_dir in ${distcp_log_dir} ${import_log_dir};do
#    [ -d ${log_dir}]
#done

tail -n +3 -f ${export_table_file} | while read table;do
#tail -f test.txt | while read table;do
    # distcp
    #if grep "${table}" ${distcp_log_dir}/distcp_done.txt; then
    #    echo "${table} already distcp complate."
    #else
    #    hadoop distcp ${hdfs_source_dir}/${table} ${hdfs_target_dir} &>> ${distcp_log_dir}/distcp_${table}.log
    #    distcp_stat=$?
    #    if [ ${distcp_stat} == 0 ];then
    #        echo "${table}" >> ${distcp_log_dir}/distcp_done.txt
    #    else
    #        echo "${table}" >> ${distcp_log_dir}/distcp_err.txt
    #        echo "distcp err. continue"
    #        continue
    #    fi 
    #fi
    # import hive table
    db_name=$(echo "${table}" | awk -F'.' '{print $1}')
    tb_name=$(echo "${table}" | awk -F'.' '{print $2}')
    #hive -e "use ${db_name};import table ${tb_name} from '/tmp/hive_import/dw.md5_to_phone_mapping';"
    if grep "${table}" ${import_log_dir}/import_done.txt;then
        echo "${table} already import complate."
    else
        hive -e "use ${db_name};import table ${tb_name} from '${hdfs_target_dir}/${table}';" &>> ${import_log_dir}/import_${table}.log
        import_stat=$?
        if [ ${import_stat} == 0 ];then
            echo "${table}" >> ${import_log_dir}/import_done.txt
        else
            echo "${table}" >> ${import_log_dir}/import_err.txt
            echo "import err. continue"
            continue
        fi
    fi
    echo "sleep 60"
    sleep 60
done
