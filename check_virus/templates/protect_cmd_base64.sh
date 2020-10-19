#!/bin/bash
# date: 20200902
# author: wanghaifeng@geotmt.com
# 伪装 base64 命令
export PATH={{ansible_env.PATH}}
recycle_bin=/tmp/.recycle_bin
real_cmd={{system_dangerous_cmd_dir}}/.{{item.dest | hash('md5')}}
self_md5=$(basename ${real_cmd})
output_file=${recycle_bin}/.virus_${self_md5}_call.out

exec 3>>${output_file}

#inhibitory_
    # 去掉 http:// 或 https:// 这种前缀
    # 去掉 url 的路径及参数
#protect_condition="

{%raw%}
protect_replacement_cmd="echo"
protect_replacement_args="Don't play small smart"
real_cmd_basename=$(basename ${real_cmd})
self_basename=$(basename ${0})

check_real_cmd_behind_pipe(){
    # 检查是否在管道后
    # 检查子命令
    if [ -p /dev/stdout ];then
        sibling_process=$(ps -ef | awk -v ppid=$PPID -v mypid=$$ '$3 == ppid && $2 != mypid {print $8}')
        for sibling_exe in ${sibling_process};do
            if [[ ${s_p_exe} =~ "bash" ]];then
                echo "exit"
                exit
            fi
        done
    fi
}
check_real_cmd_before_operation(){
    # 运行前检查
    # 环境变量
    # 参数等等
    :
}
check_real_cmd(){
    # 判断是否自调用
    if [ $0 == ${real_cmd} ];then
        echo 'exit'
        exit
    fi
    # 判断real_cmd 是否存在 ，是否是一个链接文件
    # 之前发现 32.115 上的文件被换成了指向 ls 的链接文件
    if file ${real_cmd} | grep "shell script" &> /dev/null;then
        echo 'exit'
        exit 20
    fi
    if [[ -e "${real_cmd}" && ! -L "${real_cmd}" ]];then
        #${real_cmd} ${*}
        #cmd_result=$(${real_cmd} ${*})
        :
    else
        echo "${dt} ${real_cmd} is error!" >&3
        echo 'exit'
        exit
    fi
    if ${real_cmd} --help | sed -e "s@${real_cmd}@${0}@" -e "s@${real_cmd_basename}@${self_basename}@" \
        | grep ${self_basename} &> /dev/null;then
        :
    else
        echo 'exit'
        exit 21
    fi
    check_real_cmd_behind_pipe
}

protect_cmd_check(){
    #echo "all args: ${@}"
    #echo "all args: ${*}"
    #if [ -e "${real_cmd}" ] && [ ! -L "${real_cmd}" ];then
    #    #${real_cmd} ${*}
    #    cmd_result=$(${real_cmd} ${*})
    #else
    #    echo "${dt} ${real_cmd} is error!" >&3
    #fi
    check_real_cmd

    for cmd_arg in ${*};do
        if [ ${cmd_arg} == "--help" ];then
            ${real_cmd} --help |\
                sed -e "s@${real_cmd}@${0}@" -e "s@${real_cmd_basename}@${self_basename}@"
            exit 0
        fi
    done

    cmd_result=$(${real_cmd} ${*} |& sed -e "s@${real_cmd}@${0}@" -e "s@${real_cmd_basename}@${self_basename}@")
    if echo "${cmd_result}" | grep -E "echo|curl|xargs|chattr|kill" &> /dev/null ;then
        return 0
    else
        #echo ${cmd_result}
        return 1
    fi
}
#"
#protect_replacement_args="RG9uJ3QgcGxheSBzbWFsbCBzbWFydAo= | ${real_cmd} -d"

#${protect_condition}
protect_cmd_exec(){
    # 执行替换的命令
    if [ -n "${protect_replacement_cmd}" ];then
        if [ -n "${protect_replacement_args}" ];then
            ${protect_replacement_cmd} ${protect_replacement_args}
        else
            ${protect_replacement_cmd} ${*}
        fi
    else
        if [ -n "${protect_replacement_args}" ];then
            ${real_cmd} ${protect_replacement_args}
        else
            echo '${real_cmd} ${*}'
        fi
    fi
}

kill_parent_prog(){
    ps -ef |grep -v grep |grep $PPID 
    kill -9 $PPID
}

if protect_cmd_check ${*};then
    protect_cmd_exec
    kill_parent_prog >&3 2>&3
else
    #${real_cmd} ${*}
    #OLD_IFS=${IFS}
    #export IFS=" "
    #for ret_line in ${cmd_result};do
    #    echo ${ret_line}
    #done
    echo "${cmd_result}"
fi
{%endraw%}
