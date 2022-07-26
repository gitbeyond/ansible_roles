#!/bin/bash
export PATH={{ansible_env.PATH}}

logfile={{keepalived_log_dir}}/{{keepalived_nginx_log}}
dt=$(date +%Y%m%d%H%M%S)

keep_state="Fault"

echo "${dt} [${keep_state}]" >> ${logfile}

