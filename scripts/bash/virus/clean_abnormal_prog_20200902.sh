#!/bin/bash
# date: 20200902
# author: wanghaifeng@geotmt.com
# 针对8月份一些机器上出现的异常进程编写的脚本
# 1. 杀死异常进程
# 2. 清理异常计划任务
# 3. 清理异常文件
# 4. 封禁探测ssh的ip
#set -euo pipefail
set -uo pipefail

recycle_bin=/tmp/.recycle_bin
vrius_files=(/etc/cron.d/0systemd-service)
dt=$(date +%Y%m%d%H%M%S)
dt_s=$(date +%s)

celan_abnormal_prog(){
    # lrwxrwxrwx 1 root root 0 Sep  2 11:13 /proc/490/exe -> /usr/sbin/sshd
    if ls -l /proc/*/exe 2> /dev/null |grep deleted;then
        # 2020/09 的命令写成了 x=./$(date|md5sum|cut -f1 -d-),length is 35
        ls -l /proc/*/exe |grep deleted | while read line;do

            virus_exe=$(echo ${line} | awk '{print $(NF-1)}')
            virus_pid=$(echo ${line} | awk '{print $9}' | awk -F/ '{$3}')
            virus_exe_basename=$(basename ${virus_exe})
            if [ ${#virus_exe_basename} -gt 30 ];then
                echo "abnormal_exe: ${virus_exe}"
                echo "kill -9 ${virus_pid}"
                kill -9 ${virus_pid}
                echo "rm -rf ${virus_exe}"
                rm -rf ${virus_exe}
            fi
        done
    fi
}

clean_abnormal_cron_job(){
   
    recycle_bin=/tmp/.recycle_bin
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
        [ -f ${vf} ] && /bin/mv ${vf} ${recycle_bin}/
    done
}

check_ssh_sniff(){
# Sep  2 14:08:07 docker-182 sshd[21664]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=10.111.32.100  user=root
# Sep  2 14:08:09 docker-182 sshd[21661]: error: PAM: Authentication failure for root from 10.111.32.100
# Sep  2 14:08:18 docker-182 sshd[21661]: Postponed keyboard-interactive for root from 10.111.32.100 port 49360 ssh2 [preauth]
# Sep  2 14:08:31 docker-182 sshd[21661]: Failed password for root from 10.111.32.100 port 49360 ssh2
# Sep  2 14:08:35 docker-182 sshd[21661]: error: maximum authentication attempts exceeded for root from 10.111.32.100 port 49360 ssh2 [preauth]
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
    hosts_deny_old_files=$(ls -1 -t /etc/hosts.deny.* | tail -n +10)
    if [ -n "${hosts_deny_old_files}" ];then
        echo "rm -rf ${hosts_deny_old_files}"
        /bin/mv ${hosts_deny_old_files} ${recycle_bin}
    fi
}

# 杀死异常进程
celan_abnormal_prog
# 删除异常计划任务
clean_abnormal_cron_job
# 删除异常文件
clean_abnormal_files
# 检测异常ssh连接
check_ssh_sniff

