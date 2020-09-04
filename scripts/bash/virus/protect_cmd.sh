#!/bin/bsah
# date: 20200902
# author: wanghaifeng@geotmt.com
# 伪装 curl 及 wget 命令

real_cmd=curl
#inhibitory_
    # 去掉 http:// 或 https:// 这种前缀
    # 去掉 url 的路径及参数
#protect_condition="
protect_cmd_check(){
    # 返回0表示检测成功，即符合异常，那么会被替换成默认的命令执行，
    # 或者是其它定义好的命令,比如发送邮件通知等等
    for cmd_arg in ${*};do
        #echo ${cmd_arg}
        arg=${cmd_arg#*//}
        arg=${arg%%/*}
        if [ ${#arg} -gt 50 ];then
            return 0
            break
        fi
    done
    return 1
}
#"
protect_replacement_cmd="echo"
protect_replacement_args="https://www.baidu.com"

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
if protect_cmd_check ${*};then
    protect_cmd_exec
else
    ${real_cmd} ${*}
fi
