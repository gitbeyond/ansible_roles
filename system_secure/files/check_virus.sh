
virus_pid_dir=/tmp/.X11-unix
virus_pids=$(cat ${virus_pid_dir}/* 2> /dev/null)


check_virus_pid_file(){
    for pd in ${virus_pids};do
        ps -ef |grep "${pd}"
    done
}

check_virus_exe(){
    ls -l /proc/*/exe 2> /dev/null |grep deleted
}

check_cron_job(){
    cat /var/spool/cron/* |grep '> /dev/null 2>\&1 \&' --color
}

check_virus_pid_file
check_virus_exe
check_cron_job
