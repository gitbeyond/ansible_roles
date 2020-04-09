bad_files=(
/tmp/.00
/tmp/.X*
/tmp/.font-unix
/tmp/.ICE-unix
/tmp/.Test-unix
/.autorelabel
/.readahead
/.autofsck
/root/.systemd-login
/tmp/xc.x86_64
/tmp/thisxxs
/tmp/.systemd-login
/tmp/.systemd-analyze
/tmp/systemd
/usr/bin/vtyrfa*
)

for i in ${bad_files[@]};do
    rm -rf ${i}
done

ls -a /tmp/ | while read line; do 

    if [ -x /tmp/${line} ] && [ -f /tmp/${line} ];then
        laji_pid=$(ps -ef |grep -v -E 'grep|ssh' |grep ${line} |awk '{print $2}')
        for i in ${laji_pid};do
            if ls -l /proc/${laji_pid}/exe | awk '{print $(NF-3)}' | grep "^[0-9a-zA-Z]\{6\}$" ;then
                kill -9 ${laji_pid}
            fi
        done
        rm -rf /tmp/${line}
    fi
done

laji_pid=$(ps aux |sort -k3 -n |tail -n 1 |awk '{print $2}')
echo "laji_pid: ${laji_pid}"

if ls -l /proc/${laji_pid}/exe  |grep deleted;then
    laji_exe=$(ls -l /proc/${laji_pid}/exe  |awk '{print $(NF-1)}')
    echo "laji_exe: ${laji_exe}"
    rm -rf ${laji_exe}
    kill -9 ${laji_pid}
fi

ps aux |grep -v -E 'ssh|grep' |grep  bash |grep yarn |awk '{print $2}' |while read line; do kill -9 ${line};done

ps aux  |grep -v -E 'ssh|grep' |grep yarn |awk '{print $2}' |while read line;  do 
    ls /proc/${line}/exe -l
    if ls /proc/${line}/exe -l |grep "tmp" |grep "deleted"; then
        echo "kill -9 ${line}"
        kill -9 ${line}
    fi
    #ls /proc/${line}/fd -l
    if ls /proc/${line}/fd -l |grep "tmp" |grep "deleted"; then
        echo "kill -9 ${line}"
        kill -9 ${line}
    fi
done

laji_str=$(ps aux |awk '{print $11}' | grep "^[0-9a-zA-Z]\{6\}$")
if [ -n "${laji_str}" ];then
    laji_pid=$(ps aux |grep "${laji_str}" |awk '{print $2}')
    laji_exe=$(ls /proc/${laji_pid}/exe -l |awk '{print $(NF-1)}')
    if ls -l /proc/${laji_pid}/exe  |grep deleted;then
        laji_exe=$(ls -l /proc/${laji_pid}/exe  |awk '{print $(NF-1)}')
        echo "laji_exe: ${laji_exe}"
        rm -rf ${laji_exe}
        kill -9 ${laji_pid}
    fi
fi
