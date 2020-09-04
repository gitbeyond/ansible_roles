#!/bin/bash
# date: 20200902
# author: wanghaifeng@geotmt.com
# 针对8月份一些机器上出现的异常进程编写的脚本
# 1. 杀死异常进程
# 2. 清理异常计划任务
# 3. 清理异常文件
# 4. 封禁探测ssh的ip
#set -euo pipefail
#set -uo pipefail
set -ue

recycle_bin=/tmp/.recycle_bin
vrius_files=(/etc/cron.d/0systemd-service)
dt=$(date +%Y%m%d%H%M%S)
dt_s=$(date +%s)


flock_check(){
    if [ -e ${recycle_bin} ];then
        if [ -d ${recycle_bin} ];then
            :
        else
            rm -rf ${recycle_bin}
            mkdir -p ${recycle_bin}
        fi
    else
        mkdir -p ${recycle_bin}
    fi

    local lock_file=${recycle_bin}/.clean_ab_prog.lock
    exec 5<> ${lock_file}
    
    if flock -n 5;then
        #echo "get ${lock_file} lock file."
        :
    else
        echo "get lock file failed. now exit."
        exit 5
    fi
}

proc_kill_9(){
    local virus_exe=$1
    local virus_pid=$2
    local virus_exe_basename=$(basename ${virus_exe})
    # 根据命令的长度判断是否异常,当前发现的异常进程的都是 32 个字符
    if [ ${#virus_exe_basename} -gt 30 ];then
        ps -ef |grep -v grep |grep ${virus_pid}
        echo "abnormal_exe: ${virus_exe}"
        echo "kill -9 ${virus_pid}"
        kill -9 ${virus_pid}
        echo "rm -rf ${virus_exe}"
        [ -e ${virus_exe} ] && rm -rf ${virus_exe}
    fi
}
celan_abnormal_prog(){
    # lrwxrwxrwx 1 root root 0 Sep  2 11:13 /proc/490/exe -> /usr/sbin/sshd
    if ls -l /proc/*/exe 2> /dev/null |grep deleted;then
        # 2020/09 的命令写成了 x=./$(date|md5sum|cut -f1 -d-),length is 35
        ls -l /proc/*/exe |grep deleted | while read line;do
            echo "$(date) The abnormal prog is: ${line}"
            local virus_exe=$(echo ${line} | awk '{print $(NF-1)}')
            local virus_pid=$(echo ${line} | awk '{print $9}' | awk -F'/' '{print $3}')
            proc_kill_9 ${virus_exe} ${virus_pid}   
            #virus_exe_basename=$(basename ${virus_exe})
            #if [ ${#virus_exe_basename} -gt 30 ];then
            #    echo "abnormal_exe: ${virus_exe}"
            #    echo "kill -9 ${virus_pid}"
            #    kill -9 ${virus_pid}
            #    echo "rm -rf ${virus_exe}"
            #    rm -rf ${virus_exe}
            #fi
        done
    fi
}


select_ab_prog_by_cpu_time(){
    # 根据cpu时间找出异常进程
    local ab_pids=$(ps aux |sort -k3 -n |tail -n 1 |awk '{print $2}')
    echo ${ab_pids}
}

select_ab_prog_by_character(){
    # 根据进程名找出异常进程
    local ab_pids=$(ps -ef |awk '{
        if(match($8,"\\[") == 0 && match($8,"\\/") == 0 && NF==8 && $3 == 1){
            print $2
        }
    }')
    echo ${ab_pids}
}

clean_old_ab_prog(){
    echo "${dt} clean_old_ab_prog function begin."
    local cpu_time_ab_progs=$(select_ab_prog_by_cpu_time)
    local ab_progs="${cpu_time_ab_progs} $(select_ab_prog_by_character)"
    for virus_pid in ${ab_progs};do
        # 这里得到的可能是多个值,所以需要循环一下
        local virus_exe=$([ -e /proc/${virus_pid}/maps ] && cat /proc/${virus_pid}/maps |awk '/deleted/{print $(NF-1)}')
        #if [ ${virus_pid} == $$ ];then
        #    continue
        #fi
        if [ -n "${virus_exe}" ];then
            for delete_file in ${virus_exe};do
                #local virus_exe_basename=$(basename ${virus_exe})
                proc_kill_9 ${delete_file} ${virus_pid}   
            done
        else
            echo "the prog seems like is normal."
            if ps -ef |grep -v grep |grep ${virus_pid};then
                :
            fi
        fi
    done
    echo "${dt} clean_old_ab_prog function end."
}



clean_abnormal_cron_job(){
   
    #recycle_bin=/tmp/.recycle_bin
    # 通过关键字删除计划任务
    # */10 * * * * /opt/systemd-service.sh
    abnormal_key_word='systemd-service.sh'
    grep "${abnormal_key_word}" /var/spool/cron/* | while read line;do
        # 判断是否包含了异常的字符串,包含的话打印出来
        #echo "${line}"
        #echo '-------------------'
        virus_file=$(echo "${line}" |awk -vvirus_word=${abnormal_key_word} '{
            for(i=6;i<=NF;i++){
                if(match($i,virus_word) > 0){
                    print $i    
                    break
                }
            }
        }')
        # 判断文件是否存在,存在移到临时目录
        if [ -f ${virus_file} ];then
            [ -d ${recycle_bin} ] || mkdir ${recycle_bin}
            virus_file_basename=$(basename ${virus_file})
            chattr -i ${virus_file} &> /dev/null
            /bin/mv ${virus_file} ${recycle_bin}/
            chmod -x ${recycle_bin}/${virus_file_basename}
        fi
        # 可以发送通知，用哪种方式发，待定
    done
    # 删除异常 cron job
    echo 'sed -i "/${abnormal_key_word}/d" /var/spool/cron/*'
    sed -i "/${abnormal_key_word}/d" /var/spool/cron/*
}

clean_abnormal_files(){
    # 目前发现的异常文件，这个列表要随时变动
    [ -d ${recycle_bin} ] || mkdir -p ${recycle_bin}
    for vf in ${vrius_files[@]};do
        echo "/bin/mv ${vf} ${recycle_bin}/"
        if [ -f ${vf} ];then 
            chattr -i ${vf} &> /dev/null
            /bin/mv ${vf} ${recycle_bin}/
        fi
    done
}

check_ssh_sniff(){
# Sep  2 14:08:07 docker-182 sshd[21664]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=10.111.32.100  user=root
# Sep  2 14:08:09 docker-182 sshd[21661]: error: PAM: Authentication failure for root from 10.111.32.100
# Sep  2 14:08:18 docker-182 sshd[21661]: Postponed keyboard-interactive for root from 10.111.32.100 port 49360 ssh2 [preauth]
# Sep  2 14:08:31 docker-182 sshd[21661]: Failed password for root from 10.111.32.100 port 49360 ssh2
# Sep  2 14:08:35 docker-182 sshd[21661]: error: maximum authentication attempts exceeded for root from 10.111.32.100 port 49360 ssh2 [preauth]
    echo "${dt} check_ssh_sniff begin."
    hosts_deny=/etc/hosts.deny
    # 默认为3天
    protect_tmp_refuse_time=259200
    tail -n 2000 /var/log/secure |awk '/authentication failure/{
        for(i=6;i<=NF;i++){
            if(match($i,"rhost") > 0){
                split($i,a,"=")
                print a[2]
                break
            }
        }
    }' |sort -n | uniq -c | while read line; do
        err_num=$(echo ${line} |awk '{print $1}')
        err_ip=$(echo ${line} |awk '{print $2}')
        # 如果一个ip尝试的次数大于9次了
        if [ ${err_num} -gt 9 ];then
            # 检测 ip 是否已经存在，存在的话更新时间
            if err_ip_line=$(grep -n "${err_ip}" ${hosts_deny});then
                # ip 所在的行号
                err_ip_line_num=$(echo ${err_ip_line} |awk -F: '{print $1}')
                # ip 更新的时间的行号
                err_ip_dt_line_num=$((err_ip_line_num-1))
                # 检测封禁时间是否已过期,
                err_ip_dt=$(sed -n "${err_ip_dt_line_num}p" ${hosts_deny} |awk -F'#' '{print $NF}')
                 
                # 如果ip不为空且都是数字 
                if [ -n "${err_ip_dt}" ];then
                    # 为 0 代表不是数字
                    if echo ${err_ip_dt} | grep -q '[^0-9]';then
                        # 如果某个ip没有时间信息，那么为其添加当前的时间
                        sed -i.${dt} "${err_ip_dt_line_num}a#${dt_s}" ${hosts_deny}
                    else
                        # 如果其存在时间大于 3 天了，那么将其删除
                        diff_dt=$((dt_s-err_ip_dt))
                        if [ ${diff_dt} -gt ${protect_tmp_refuse_time} ];then
                            #sed -i.${dt} -e "/#${err_ip_dt}/d" -e "/${err_ip}/d" ${hosts_deny}
                            sed -i.${dt} "${err_ip_dt_line_num},${err_ip_line_num}d" ${hosts_deny}
                        fi
                    fi
                else
                    # 如果某个ip没有时间信息，那么为其添加当前的时间
                    sed -i.${dt} "${err_ip_dt_line_num}a#${dt_s}" ${hosts_deny}
                fi
            else
                # 不存在的话，将其添加到文件当中
                echo -e "#${dt_s}\nsshd:${err_ip}:deny" >> ${hosts_deny}
            fi
        fi
    done
    hosts_deny_old_files=$(ls -1 -t /etc/hosts.deny.* 2> /dev/null | tail -n +10)
    if [ -n "${hosts_deny_old_files}" ];then
        echo "rm -rf ${hosts_deny_old_files}"
        /bin/mv ${hosts_deny_old_files} ${recycle_bin}
    fi
    echo "${dt} check_ssh_sniff end."
}

my_main(){
    # 检查锁文件
    flock_check
    # 找出之前的异常进程
    clean_old_ab_prog
    # 杀死异常进程
    celan_abnormal_prog
    # 删除异常计划任务
    clean_abnormal_cron_job
    # 删除异常文件
    clean_abnormal_files
    # 检测异常ssh连接
    check_ssh_sniff
}
my_main
