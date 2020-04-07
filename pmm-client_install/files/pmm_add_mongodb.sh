#!/bin/bash
export PATH=/usr/sbin:$PATH

pmm_mongo_user=$1
pmm_mongo_pass=$2
pmm_mongo_cluster_name=$3
#pmm_socket=$3
pmm_mongo_server=$4
pmm_mongo_port=$5
pmm_server=$6
pmm_info_update=$7
#pmm_info_update=${pmm_info_update:-false}
pmm_instance_name=$8
pmm_mongodb_exporter_args=$9
pmm_local_server=$(pmm-admin info |awk '/PMM Server/{print $NF}')
pmm_hostname=$(hostname -f)
pmm_mongo_uri=mongodb://${pmm_mongo_user}:${pmm_mongo_pass}@${pmm_mongo_server}:${pmm_mongo_port}/admin
#if [ -n "${pmm_instance_name}" ] || [ "${pmm_instance_name}" == "False" ];then

if [ "${pmm_instance_name}" != "false" ];then
    pmm_instance_name=${pmm_hostname}_${pmm_instance_name}
else
    pmm_instance_name=${pmm_hostname}
fi

pmm_add_config(){
    if [ "${pmm_local_server}" == "${pmm_server}" ];then
        echo "pmm_server:1"
    else
        pmm-admin config --server ${pmm_server}
    fi
}

pmm_remove_mongodb(){
    local mongo_instance=$1
    if [ -n "${mongo_instance}" ];then
        pmm-admin remove mongodb ${mongo_instance}
        pmm_rm_stat=$?
    else
        pmm-admin remove mongodb
        pmm_rm_stat=$?
    fi
    return ${pmm_rm_stat}
}

pmm_add_mongodb(){
    local mongo_instance=$1
    if [ -n "${mongo_instance}" ];then
        :
    else
        mongo_instance=${pmm_hostname}
    fi
    # 执行循环添加 mongodb 的监控
    # mongodb:queries  暂时不支持 --mongodb.tls 的参数，关于证书的参数需要写在 uri 中，这个写法暂时忽略
    # tls=true&tlsCertificateKeyFile= &tlsCAFile=
    #for tp in metrics queries;do
    for tp in metrics;do
        pmm_mongo_info=$(pmm-admin list |awk '/^mongodb:'$tp'/{print $2}')        
        if [ "${pmm_mongo_info}" == "${mongo_instance}" ];then
            echo "the mongodb:${tp} ${mongo_instance} already exist."
        else
            if [ -n "${pmm_mongodb_exporter_args}" ];then
                if [ ${tp} == queries ];then
                    echo "pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri}   ${mongo_instance} -- ${pmm_mongodb_exporter_args}"
                    pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri} ${mongo_instance} -- ${pmm_mongodb_exporter_args}
                    pmm_add_stat=$?
    
                else
                    echo "pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name}  ${mongo_instance} -- ${pmm_mongodb_exporter_args}"
                    pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name} ${mongo_instance} -- ${pmm_mongodb_exporter_args}
                    pmm_add_stat=$?
                fi

            else
                if [ ${tp} == queries ];then
                    echo "pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri} ${mysql_instance}"
                    pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri} ${mongo_instance}
                    pmm_add_stat=$?

                else
                    echo "pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name} ${mysql_instance}"
                    pmm-admin add mongodb:${tp} --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name} ${mongo_instance}
                    pmm_add_stat=$?
                fi
            fi
        fi

    done

    #pmm_select_name=$(pmm-admin list --json |tail -n 1 | jq ' .Services |map(select(.Name=="'${mongo_instance}'"))')
    #if [ ${#pmm_select_name} -gt 2 ];then
    #    echo "the ${mongo_instance} already exist." 
    #    pmm_add_stat=$?
    #else
    #    # 现在 pmm-admin add mongodb 是不行的，只能使用 mongodb:metrics 或者 mongodb:queries
    #    

    #    if [ -n "${pmm_mongodb_exporter_args}" ];then
    #        echo "pmm-admin add mongodb:metrics --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name}  ${mongo_instance} -- ${pmm_mongodb_exporter_args}"
    #        pmm-admin add mongodb --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name} ${mongo_instance} -- ${pmm_mongodb_exporter_args}
    #        pmm_add_stat=$?
    #    else
    #        echo "pmm-admin add mongodb --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name} ${mysql_instance}"
    #        pmm-admin add mongodb --uri ${pmm_mongo_uri} --cluster ${pmm_mongo_cluster_name} ${mongo_instance}
    #        pmm_add_stat=$?
    #    fi
    #fi

    return ${pmm_add_stat}
}

pmm_add_config
# 更新操作的话，先删除，再添加
if [ "${pmm_info_update}" == "True" ];then
    echo "pmm-admin remove mongodb"
    #pmm-admin remove mysql
    pmm_remove_mongodb ${pmm_instance_name}
    if [ $? == 0 ];then 
        echo "pmm-admin remove mongodb succed."
    else
        echo "pmm-admin remove mongodb failed."
        exit 1
    fi
fi

pmm_add_mongodb ${pmm_instance_name}
