#!/bin/bash
# date: 2020/09/17
# author: wanghaifeng@geotmt.com

# 这个是迁移 32.25 的 hive 表到 32.34 集群上时写的脚本
# 此脚本的操作方式是直接复制表的数据，然后建表，修复分区，比之前 export , distcp, import 要高效
# 脚本使用时，需要先将旧集群的库，表等信息，写入文本，然后操作这些文本，来节省每次都用beeline 查询的等待时间
# 脚本匆忙写就，有一些问题:
# 1. 当运行完一次后，想要重试时，这个尚未很好的实现，默认的是这个表只要在 success 文件中，就不会重试，也就是说只会重试那些在 failed 文件中的表
# 2. 有一些表比较特殊，可能没有考虑周全，遇到此类表时，需要单独进行处理。
# 3. 另有一些变量，如 hdfs 的 namespace 是是写死的，并未采用变量

old_url='jdbc:hive2://hadoop25.geotmt.com:2181,hadoop26.geotmt.com:2181,hadoop206.geotmt.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2'
#new_url='jdbc:hive2://hadoop35.geotmt.com:2181,hadoop34.geotmt.com:2181,hadoop36.geotmt.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2'
new_url='jdbc:hive2://hadoop35.geotmt.com:10000'

new_hdfs_host=hdfs://10.111.32.34:8020
old_hdfs_nm=geocluster
new_hdfs_nm=testcluster
dt=$(date +%Y%m%d%H%M%S)
dbs_txt=dbs.txt
tbs_txt=tbs.txt
tb_create_info=create_info.txt

hive_create_db(){
    # 生成创建数据库的语句
    create_db_statment=$(cat ${dbs_txt} | while read db_name; do 
        echo "create database if not exists ${db_name};"
    done)
    
    # 新集群上创建库
    beeline --outputformat=vertical --silent=true -u "${new_url}" -e "${create_db_statment}"
}

hive_get_db_and_table(){
    # 将所有库名存放到 一个文本文件中
    local db_txt=${dbs_txt}
    local tb_txt=${tbs_txt}
    #local my_tb_create_info=${tb_create_info}
    beeline --outputformat=vertical --silent=true -u "${old_url}" -e "show databases;" | awk '$1!=""{print $2}' > ${db_txt}
    
    # 根据库名得到所有表名
    cat ${db_txt} | while read line; do 
        [ -d ${line} ] || mkdir -p ${line}
        beeline --outputformat=vertical --silent=true -u "${old_url}" -e "show tables from ${line};" |awk '$1!=""{print $2}' > ${line}/${line}_${tb_txt}
    done

    # 得到所有表的建表语句
    cat ${db_txt} |while read line;do
        cat ${line}/${line}_${tb_txt} |while read tb;do
            # 末尾没有分号
            beeline --outputformat=csv2 --showHeader=false --silent=true -u "${old_url}" -e  "show create table ${line}.${tb};" > ${line}/${tb}_${tb_create_info}
            #break
        done
        #break
    done
}

hive_data_distcp(){
    local distcp_success_log=$1
    local distcp_failed_log=$2
    local distcp_source_url=$3
    local distcp_dest_url=$4
    
}

distcp_success_log=distcp_success.txt
distcp_failed_log=distcp_failed.txt
rebuild_table_success_log=rebuild_table_success.txt
rebuild_table_failed_log=rebuild_table_failed.txt
# 在新集群建表，并复制数据
#cat dbs.txt_all |while read line;do
cat ${dbs_txt} |while read line;do
    cat ${line}/${line}_${tbs_txt} |while read tb;do
        # 末尾没有分号
        #beeline --outputformat=csv2 --showHeader=false --silent=true -u "${old_url}" -e  "show create table ${line}.${tb};" > ${line}/${tb}_create_info.txt
     
        # beeline 重定向的文件是 csv2 的，不是纯文本的，其中有些特殊符号
        # 这个变量的值类似 'hdfs://geocluster/services/data/hive/warehouse/kylin_cal_dt'
        touch ${line}/${distcp_success_log}
        touch ${line}/${distcp_failed_log}
        touch ${line}/${rebuild_table_success_log}
        touch ${line}/${rebuild_table_failed_log}
        tb_create_info=$(cat ${line}/${tb}_create_info.txt)
        # 如果表的创建语句文件不存在，就进入下次循环
        if [ -n "${tb_create_info}" ];then
            :
        else
            echo "${dt} ${line}.${tb}" >> ${line}/table_info_is_empty.txt
            continue
        fi
        # 获取表的 location 
        old_full_hdfs_url=$(echo "${tb_create_info}" |grep -A 1 LOCATION |grep hdfs)
        old_hdfs_path_tmp=${old_full_hdfs_url#*${old_hdfs_nm}} 
        old_hdfs_path=${old_hdfs_path_tmp%\'}
     
        # 如果 location 不存在的话，报错
        if [ -n "${old_hdfs_path}" ];then
            :
        else
            echo "${dt} ${line}.${tb}" >> ${line}/table_path_is_error.txt
            continue
        fi

        # 判断是否已经 distcp 完成，未完成则开始 distcp
        if grep "${line}.${tb}" ${line}/${distcp_success_log} > /dev/null;then
            echo "the ${line}.${tb} already distcp successed."
        else
            hdfs dfs -mkdir -p /tmp/distcp_log/distcp_${line}
            hadoop distcp \
                -Dmapreduce.job.name=distcp_${line} \
                -update -delete -log /tmp/distcp_log/distcp_${line} \
                -numListstatusThreads 40 \
                -pb \
                ${old_hdfs_path} ${new_hdfs_host}${old_hdfs_path} &>> /tmp/distcp_${line}.out
                #${source_hdfs_dir}/${db} ${dest_hdfs_dir}/${db} &>> /tmp/distcp_${db}.out
            distcp_stat=$?
        fi
        # 完成后根据状态，生成日志
        distcp_stat=${distcp_stat:-0}
        if [ ${distcp_stat} == 0 ];then
            if grep "${line}.${tb}" ${line}/${distcp_success_log} &> /dev/null;then
                :
            else
                echo "${dt} ${line}.${tb}" >> ${line}/${distcp_success_log}
            fi
            #if [ -f ${line}/${distcp_failed_log} ];then
                if grep "${line}.${tb}" ${line}/${distcp_failed_log} &> /dev/null;then
                    sed -i "/${line}.${tb}/d" ${distcp_failed_log}
                fi
            #fi
        else
            # 错了的话，就直接进行下一个
            #echo "${dt} ${line}.${tb}" >> ${line}/${distcp_failed_log}
            # 当目录为空时 distcp 会报错，但是表应该继续创建才对
            #continue
            if grep "${line}.${tb}" ${line}/${distcp_failed_log} &> /dev/null;then
                sed -i "/${line}.${tb}/c ${dt} ${line}.${tb}"  ${line}/${distcp_failed_log}
            fi
        fi
        #create_table_statement_tmp=$(cat ${line}/${tb}_create_info.txt)
        #create_table_statement=${tb_create_info/hdfs:\/\/geocluster/hdfs://dpcluster}
        # 获取建表语句
        #create_table_statement=${tb_create_info//hdfs:\/\/geocluster/hdfs://testcluster}
        create_table_statement=${tb_create_info//hdfs:\/\/${old_hdfs_nm}/hdfs://${new_hdfs_nm}}
        create_table_statement=${create_table_statement/CREATE TABLE/CREATE TABLE IF NOT EXISTS}
        create_table_statement=${create_table_statement/CREATE EXTERNAL TABLE/CREATE EXTERNAL TABLE IF NOT EXISTS}
      
        # 判断是否已建表，未建则执行命令进行创建
        if grep "${line}.${tb}" ${line}/${rebuild_table_success_log} &> /dev/null;then
            echo "the ${line}.${tb} already rebuild successed."
            continue
        else
            beeline -n hdfs --outputformat=csv2 --silent=true -u "${new_url}" -e "${create_table_statement}; msck repair table ${line}.${tb};"
            rebuild_table_stat=$?
        fi
        #touch ${line}/${rebuild_table_failed_log}
        # 记录或更新日志
        rebuild_table_stat=${rebuild_table_stat:-0} 
        if [ ${rebuild_table_stat} == 0 ];then
            if grep "${line}.${tb}" ${line}/${rebuild_table_success_log} &> /dev/null;then
                :
            else
                echo "${dt} ${line}.${tb}" >> ${line}/${rebuild_table_success_log}
            fi
            #if [ -f ${line}/${rebuild_table_failed_log} ];then
                if grep "${line}.${tb}" ${line}/${rebuild_table_failed_log} &> /dev/null; then
                    sed -i "/${line}.${tb}/d" ${line}/${rebuild_table_failed_log}
                fi
            #fi
        else
            #echo "${dt} ${line}.${tb}" >> ${line}/${rebuild_table_failed_log}
            #echo "${dt} ${line}.${tb}" >> ${line}/${rebuild_table_failed_log}
            if grep "${line}.${tb}" ${line}/${rebuild_table_failed_log} > /dev/null; then
                sed -i "/${line}.${tb}/c ${dt} ${line}.${tb}"  ${line}/${rebuild_table_failed_log}
            fi
        fi
       
        #break
    done
    #break
done


#beeline --outputformat=vertical --silent=true -u "${old_url}" -e "show databases;" | while read db_info db_name; do
#    if [ -n "${db_name}" ];then
#        #beeline --outputformat=vertical --silent=true -u "${old_url}" -e "show create database ${db_name}; describe database ${db_name};"
#        beeline --outputformat=vertical --silent=true -u "${old_url}" -e "describe database ${db_name};"
#    fi
#done
