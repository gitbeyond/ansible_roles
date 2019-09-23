#!/bin/bash

export PATH={{ansible_env.PATH}}

catalina_logs_dir=(
/data/apps/opt/civp/logs
/data/apps/opt/service/logs
)
catalina_stdout_dir=(
/data/apps/log/civp
/data/apps/log/service
)
catalina_log4j_dir=(
/data/apps/opt/civp/log4j2logs
/data/apps/opt/service/log4j2logs
)

keep_days=7
day7_seconds=$[keep_days*86400]
day7_ago_with_hour=$(date -d "${day7_seconds} seconds ago" +%Y-%m-%d-%H)
day7_ago=$(date -d "${day7_seconds} seconds ago" +%Y-%m-%d)
dt_week_day=$(date +%w)

for dir in ${catalina_logs_dir[@]};do
    echo "cd ${dir}"
    cd ${dir}
    find ./ -name "localhost_access_log*.txt" -and -mtime +10 -print 
    echo "begin deleting..."
    find ./ -name "localhost_access_log*.txt" -and -mtime +10 -exec rm -rf {} \;
done

for dir in ${catalina_stdout_dir[@]};do
    echo "cd ${dir}"
    cd ${dir}
    find ./ -name "*gc*.log" -and -mtime +20 -print 
    echo "begin deleting..."
    find ./ -name "*gc*.log" -and -mtime +20 -exec rm -rf {} \;
done
for dir in ${catalina_log4j_dir[@]};do
    echo "cd ${dir}"
    cd ${dir}
    #find ./ -name "global*.log" -and -mtime +10 -print 
    echo "rm -rf global*${day7_ago}*.log"
    rm -rf global*${day7_ago}*.log    
    echo "begin deleting..."
    #find ./ -name "global*.log" -and -mtime +10 -exec rm -rf {} \;

    if [ ${dt_week_day} == 6 ];then
        echo "delete app/warn.log"
        [ -e app/warn.log ] && echo 0 > app/warn.log 
        echo "delete app/error.log"
        [ -e app/error.log ] && echo 0 > app/error.log 
    fi
done

