#!/bin/bash

node_exporter_textfile_directory={{node_exporter_textfile_directory}}
metric_file=realserver.prom
metric_file_full_path=${node_exporter_textfile_directory}/${metric_file}
metric_name=node_ipvs_realserver_status

check_realserver(){
    echo "# HELP ${metric_name} realserver running status, 0 : error, 1 : running"
    echo "# TYPE ${metric_name} gauge"
    /etc/init.d/realserver status
    if [ $? == 0 ];then
        echo "${metric_name} 1"
    else
        echo "${metric_name} 0"
    fi
}

if [ -d ${metric_file_full_path} ];then 
    check_realserver > ${metric_file_full_path}_1 && /bin/mv ${metric_file_full_path}_1 ${metric_file_full_path}
else
    exit 1
fi


