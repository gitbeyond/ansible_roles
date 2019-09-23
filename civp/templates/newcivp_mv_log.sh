#!/bin/bash

export PATH={{ansible_env.PATH}}

dest_base_dir={{dest_base_dir}}
prog_dir=/opt/tomcat
prog=({{source_log_dir |join(' ')}})
log_dir=(logs log4j2logs)
declare -A log_map
log_map=([logs]="catalina catalina.out localhost localhost_access_log" [log4j2logs]="global global_api_inner global_api_outside")

{% raw %}
# 循环应用程序目录
for p in ${prog[@]};do
    # 循环应用程序下的 tomcat 日志和 业务日志目录
    for dir in ${log_dir[@]};do
        if [ -d ${prog_dir}/${p}/${dir} ];then
            cd ${prog_dir}/${p}/${dir}
            echo "cd ${prog_dir}/${p}/${dir}"
            pwd
        else
            echo "the ${prog_dir}/${p}/${dir} is not exist. continue"
            continue
        fi
#        for i in ${log_map[${dir}]};do
#            echo "log name is ${i}"
#            sleep 1
#        done
        
        log_type=${log_map[${dir}]}
        dest_dir=${dest_base_dir}/${p}/${dir}
        # 遍历一个天数，2 到 10天前的日志都会移动。这是因为最初有些2天前的日志也没有移动的原因
        for num in {2..10};do
            dt=$(date -d "${num} day ago" +%F)
            dir_dt=$(date -d ${dt} +%Y%m)
            # 遍历日志名称，如 catalina,  catalina.out 等等        
            for i in ${log_type};do
                if ls ${i}.${dt}* &> /dev/null;then
                    # 如归档目录不存在，则创建目录
                    if test -e ${dest_dir}/${dir_dt}/${i};then
                        :
                    else
                        echo "mkdir -p ${dest_dir}/${dir_dt}/${i}"
                        mkdir -p ${dest_dir}/${dir_dt}/${i}
                    fi
                    echo "mv ${i}.${dt}* to ${dest_dir}/${dir_dt}/${i}/"
                    mv ${i}.${dt}* ${dest_dir}/${dir_dt}/${i}/
                fi
            done
        done
    done
done

echo "======================================="
# delete old log dir
for prog_name in ${prog[@]};do
    for log_type in ${log_dir[@]};do
        #echo "cd ${dest_base_dir}/${prog_name}_logs/${log_type}"
        #cd ${dest_base_dir}/${prog_name}/${log_type}
        if [ -d ${dest_base_dir}/${prog_name}/${log_type} ];then
            cd ${dest_base_dir}/${prog_name}/${log_type}
            echo "cd ${dest_base_dir}/${prog_name}/${log_type}"
            echo 'find ./ \( -name "*.log" -or -name "catalina.out.*" \) -and -mtime +7 -exec rm -rf {} \;'
            find ./ \( -name "*.log" -or -name "catalina.out.*" \) -and -mtime +7 -exec rm -rf {} \;
            pwd
        else
            echo "the ${dest_base_dir}/${prog_name}/${log_type} is not exist. continue"
            continue
        fi
        date_dir=($(ls -1 |grep "[0-9]"))
        echo "${prog_name}/${log_type}   ${date_dir[@]}"

        length=${#date_dir[@]}

        #if [ ${length} -eq 4 ];then
        if [ ${length} -eq 3 ];then
            echo "old version is three."
        else
            #diff=$[length-4]
            diff=$[length-3]
            for((i=0;i<${diff};i++));do
                echo "delete ${date_dir[${i}]}"
                rm -rf ${date_dir[${i}]}
            done
        fi

    done
done
app_warn_log=${prog_dir}/civp/log4j2logs/app/warn.log
app_error_log=${prog_dir}/civp/log4j2logs/app/error.log
echo "delete ${app_warn_log}"
echo 0 > ${app_warn_log}
echo "delete ${app_error_log}"
echo 0 > ${app_error_log}
echo "--------------------`date` end-----------------"
# delete old gc log
echo 'find /data/apps/log -name "*gc*.log" -mtime +180 -exec rm -rf {} \;'
find /data/apps/log -name "*gc*.log" -mtime +180 -exec rm -rf {} \;
{% endraw %}
