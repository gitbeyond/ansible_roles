#!/bin/bash
# 脚本的作用是更新 zabbix mysql 数据库中的分区
export PATH=/usr/local/mysql/bin:/usr/lib64/qt-3.3/bin:/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

# 保留分区的天数,以此为基准删除180天以前的分区
KeepPartDays=360
KeepPartSeconds=$[KeepPartDays*24*60*60]
# 当前时间
now_seconds=$(date +%s)
# 新分区的时间粒度
part_interval=$[1*24*60*60]
# 以当前时间为基准的未用的新分区的数量
new_parts=240
NewPartSeconds=$[now_seconds+new_parts*part_interval]
# 需要来更新分区的表名
part_table=(history history_uint)
#part_table=(history_uint)
#out_file=/tmp/${0/.sh/.out}
out_file=/tmp/$(basename ${0/.sh/.out})
#mysql='mysql --defaults-file=/root/zabbix_partitions/.my.cnf'
mysql='mysql --defaults-file=~/.my.cnf'
#[ -e /tmp/mysql.sock ] || ln -sv /var/lib/mysql/mysql.sock /tmp/mysql.sock

part_max() {
    ${mysql} information_schema -Bse "select MAX(PARTITION_DESCRIPTION) from partitions where table_name='$1' and table_schema='zabbix';"
}
part_min() {
    ${mysql} information_schema -Bse "select MIN(PARTITION_DESCRIPTION) from partitions where table_name='$1' and table_schema='zabbix';"
}
echo "$(date) ------------------------------" >> ${out_file}
for i in ${part_table[@]};do
    ### delete old partitions
    old_part_desc=$(part_min "${i}")
    old_keep_seconds=$[now_seconds-KeepPartSeconds]
    old_part_name=$(${mysql} information_schema -Bse "select partition_name from partitions where table_name='${i}' and table_schema='zabbix' and PARTITION_DESCRIPTION<${old_keep_seconds};")
    #echo "${i}:${old_part_name}"
    if [[ -z ${old_part_name} ]];then
        echo "old_part_name is empty;"
        exit 10
    else
        echo ${old_part_name}
        for j in ${old_part_name};do
            echo "`date +%Y%m%d%H%M%S`:delete $i:$j" >> ${out_file} 
            ${mysql} zabbix -e "alter table ${i} drop partition ${j};" &>> ${out_file}
        done
    fi
    ### add new parittions
    last_part_desc=$(part_max "${i}")
    diff_seconds=$[NewPartSeconds-last_part_desc]
    new_part_num=$[diff_seconds/part_interval]
    new_part_desc=$[last_part_desc+part_interval]
    for ((k=1;k<=${new_part_num};k++));do
        new_part_name=p$(date -d @${new_part_desc} +%Y%m%d)

        add_statement="partition ${new_part_name} values less than(${new_part_desc})"

        echo "`date +%Y%m%d%H%M%S`:${i}:${k} ${new_part_name}:${add_statement}" >> ${out_file}
        ${mysql} zabbix -e "alter table ${i} add partition (partition ${new_part_name} values less than(${new_part_desc}));" &>> ${out_file}
        new_part_desc=$[new_part_desc+part_interval]
    done 
done
