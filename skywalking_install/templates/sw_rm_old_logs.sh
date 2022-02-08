#!/bin/bash
sw_log_dir={{sw_log_dir}}
sw_nacos_log_dir=/home/{{sw_run_user}}/logs/nacos

delete_oap_server_logs(){
    if [ -d ${sw_log_dir} ];then
        cd ${sw_log_dir}
    else
        exit 0
    fi
    for i in {1..100};do
        dt=$(date -d '-1 month -'${i}' day' +'%Y-%m-%d')
        # 1..30 是oap-server自己的日志滚动的方式
        old_logs=$(ls skywalking-oap-server-${dt}-{1..30}.log 2> /dev/null)
        if [ -n "${old_logs}" ];then
            echo "rm ${old_logs}"
            /bin/rm ${old_logs}
        fi
    done
    cd -
}

delete_oap_nacos_logs(){
    if [ -d ${sw_nacos_log_dir} ];then
        cd ${sw_nacos_log_dir}
    else
        exit 0
    fi
    for i in {1..100};do
        dt=$(date -d '-2 month -'${i}' day' +'%Y-%m-%d')
        # 1..30 是oap-server自己的日志滚动的方式
        naming_old_logs=$(ls naming.log.${dt}.{1..30} 2> /dev/null)
        config_old_logs=$(ls config.log.${dt}.{1..30} 2> /dev/null)
        if [ -n "${naming_old_logs}" ];then
            echo "rm ${naming_old_logs}"
            /bin/rm ${naming_old_logs}
        fi
        if [ -n "${config_old_logs}" ];then
            echo "rm ${config_old_logs}"
            /bin/rm ${config_old_logs}
        fi
    done
    cd -
}
delete_webapp_logs(){
    if [ -d ${sw_log_dir} ];then
        cd ${sw_log_dir}
    else
        exit 0
    fi 
    dt=$(date +%Y%m%d%H%M%S)
    restart=0
    max_size=104857600
    webapp_log_size=$(du -bs webapp.log |awk '{print $1}')
    console_log_size=$(du -bs webapp-console.log |awk '{print $1}')
    if [ ${webapp_log_size} -gt ${max_size} ];then
        mv webapp.log webapp.log.${dt}
        restart=1
    fi
    if [ ${console_log_size} -gt ${max_size} ];then
        mv webapp-console.log webapp-console.log.${dt}
        restart=1
    fi
    # 普通用户无法执行这一条指令
    if [ ${restart} == 1 ];then
        systemctl restart skywalking-webapp
    fi
    # 删除旧的日志,超过10个的
    old_webapp_logs=$(ls -t1 webapp.log.* |tail -n +11)
    old_console_logs=$(ls -t1 webapp-console.log.* |tail -n +11)
    if [ -n "${old_webapp_logs}" ];then
        echo "/bin/rm ${old_webapp_logs}"
        /bin/rm ${old_webapp_logs}
    fi
    if [ -n "${old_console_logs}" ];then
        echo "/bin/rm ${old_console_logs}"
        /bin/rm ${old_console_logs}
    fi
}

main(){
    delete_oap_server_logs
    delete_oap_nacos_logs
    #delete_webapp_logs
}
main
