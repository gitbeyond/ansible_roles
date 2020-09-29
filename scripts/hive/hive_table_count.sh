# 遍历所有表，对各表执行 count() 检测迁移后的表与当前表是否一致
# 这个只是在新集群上执行的
# 实际运行时，这个运行的时候，再把此脚本复制一份修改了 beeline 的 -u 参数，再在旧集群上运行，两个集群同时执行查询
# 最后使用 diff 对比两个结果文件
> /tmp/new_cluster_table_line.out

#cat dbs.txt_all | while read line; do 
cat dbs.txt | while read line; do 

    cat ${line}/${line}_tbs.txt | while read tb; do
        tb_create_info=$(cat ${line}/${tb}_create_info.txt)
        tb_first_field_tmp=$(echo "${tb_create_info}" | grep -i string | head -n 1 | awk '{print $1}')
        tb_first_field=${tb_first_field_tmp:1: -1}
        tb_first_field=${tb_first_field:-1}
        tb_line=$(beeline -n hdfs --showHeader=false --outputformat=csv2 --silent=true -u jdbc:hive2://hadoop35.geotmt.com:10000 -e "select count(${tb_first_field}) from ${line}.${tb};")
        echo "${line}.${tb} ${tb_line}" >> /tmp/new_cluster_table_line.out 
    done
done
