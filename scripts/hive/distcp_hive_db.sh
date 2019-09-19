#!/bin/bash
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/node/bin:/data4/apps/maven/bin:/usr/local/jdk1.8.0_73/bin:/usr/local/jdk1.8.0_73/jre/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

#dbs=(aiaccess.db aimart.db yzmart.db yzaccess.db)
dbs=(aimart.db yzmart.db yzaccess.db aiaccess.db)
#dbs=( aimart.db )
#dbs=(yzmart.db)
#dbs=(yzaccess.db)
#dbs=(yzmart.db)
mail_script=/data/apps/data/script/send_mail.py
#source_hdfs_dir=/apps/hive/warehouse
#source_hdfs_dir=hdfs://nn1.geotmt.com:8020/apps/hive/warehouse
#dest_hdfs_dir=hdfs://172.16.33.52:8020/user/hdfs/databackup/hive_33.14
#dest_hdfs_dir=hdfs://nn51.geotmt.com:8020/user/hdfs/databackup/hive_33.14
dest_hdfs_dir=hdfs://hahdfs/user/hdfs/databackup/hive_33.14

#project_name=
#mail_text=

if hdfs dfs -ls hdfs://nn1.geotmt.com/ ;then

    source_hdfs_dir=hdfs://nn1.geotmt.com:8020/apps/hive/warehouse
elif hdfs dfs -ls hdfs://nn2.geotmt.com/;then
    source_hdfs_dir=hdfs://nn2.geotmt.com:8020/apps/hive/warehouse
else
    echo "the source_hdfs_dir is error."
    exit 5
fi
# -Ddistcp.bytes.per.map=1073741824 -Ddfs.client.socket-timeout=240000000 -Dipc.client.connect.timeout=40000000
        #-m 200 \
for db in ${dbs[@]};do
    echo ${db}
    #hadoop distcp -i -m 20 -update -delete ${source_hdfs_dir}/${db} ${dest_hdfs_dir}/${db} &>> /tmp/distcp_${db}.out
    #-Dmapreduce.job.name=cpdata
    #-Dmapreduce.job.queuename=default
    #hadoop distcp -Ddistcp.bytes.per.map=1073741824 \
        #hadoop distcp -Ddistcp.bytes.per.map=134217728 \
        #    -i -update -delete \
        #    -Dmapred.map.tasks=200 \
        #    -Dmapred.min.split.size=67108864 \
        #    -Ddfs.client.socket-timeout=240000000 \
        #    -Dipc.client.connect.timeout=400000000 \
        #    -Dmapreduce.job.name=distcp_${db} \
        #    -Dmapreduce.map.memory.mb=2048 \
        hdfs dfs -mkdir -p /tmp/distcp_log/distcp_${db}
        hadoop distcp \
            -Dmapreduce.job.name=distcp_${db} \
            -update -delete -log /tmp/distcp_log/distcp_${db} \
            -numListstatusThreads 40 \
            -pb \
            ${source_hdfs_dir}/${db} ${dest_hdfs_dir}/${db} &>> /tmp/distcp_${db}.out
        distcp_stat=$?
        echo "hadoop distcp -i -m 20 -update -delete ${source_hdfs_dir}/${db} ${dest_hdfs_dir}/${db} &>> /tmp/distcp_${db}.out"

        project_name=distcp_${db}
        if [ ${distcp_stat} == 0 ];then
            echo "distcp ${db} succed."
        else
            mail_text="`date` ${project_name} distcp ${db} failed."
            echo ${mail_text}
            /usr/bin/python ${mail_script} "${mail_text}"
        fi 
        #sleep 300
done
