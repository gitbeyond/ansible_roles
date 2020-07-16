#!/bin/bash

node_exporter_textfile_directory={{node_exporter_textfile_directory}}
lock_file=${node_exporter_textfile_directory}/.check_realserver.lock
metric_file=realserver.prom
metric_file_full_path=${node_exporter_textfile_directory}/${metric_file}
metric_name=node_ipvs_realserver_status

exec 3<> ${lock_file}

if flock -n 3;then
    #echo "get ${lock_file} lock file."
    :
else
    echo "get lock file failed. now exit."
    exit 5
fi


check_realserver(){
    echo "# HELP ${metric_name} realserver running status, 0 : error, 1 : running"
    echo "# TYPE ${metric_name} gauge"
    /etc/init.d/realserver status &> /dev/null
    if [ $? == 0 ];then
        echo "${metric_name} 1"
    else
        echo "${metric_name} 0"
    fi
}

if [ -d ${node_exporter_textfile_directory} ];then 
    check_realserver > ${metric_file_full_path}_1 && /bin/mv ${metric_file_full_path}_1 ${metric_file_full_path}
else
    exit 1
fi


