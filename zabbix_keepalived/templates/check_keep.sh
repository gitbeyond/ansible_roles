#!/bin/bash
export PATH={{ ansible_env["PATH"] }}

keep_conf=/etc/keepalived/keepalived.conf
keep_log=$(ls /var/log/keepalived/keep*.log)

show_ip() {
    net_info=($(ip rou sh |grep default |awk '{l1=length($3);print substr($3,0,l1-1),$NF}'))
    net=${net_info[0]}
    iface=${net_info[1]}
    line_num=3
    while true;do
        if grep -A ${line_num} "virtual_ipaddress" ${keep_conf} | grep "}" &> /dev/null;then
            break
        else
            line_num=$[line_num+1]
        fi
    done
    vips=($(grep -A ${line_num} "virtual_ipaddress" ${keep_conf} | grep "${net}" | awk '{print $1}'))
    ip_is_run=0
    for vip in ${vips[@]};do
        if ip a show ${iface} | grep ${vip} &> /dev/null;then
            ip_is_run=$[ip_is_run+1]
        fi
    done
    echo ${ip_is_run}
}

keepstate=$(tail -n 10 ${keep_log} | grep -o "\[.*\]" | tail -n 1)

arg1=$1

case ${1} in
    vip)
        show_ip 
    ;;
    keep_state)
        case ${keepstate} in
            "[Master]"|"[master]")
                echo "0"
            ;;
            "[Backup]"|"[backup]")
                echo "1"
            ;;
            "[Fault]"|"[fault]")
                echo "2"
            ;;
            "[Stop]"|"[stop]")
                echo "3"
            ;;
        esac
    ;;
    *)
        echo "USAGE: (vip|keep_state)"
    ;;
esac
