virsh list | tail -n +3 | head -n -1 | awk '{print $2}' |  while read line;do
    vm_pid=$(ps aux |grep -v grep | grep ${line} |awk '{print $2}')
    echo "${line} pid is ${vm_pid}"
    echo "kill ${vm_pid}"
    kill ${vm_pid}
    sleep 5
    echo "virsh start ${line}"
    virsh start ${line}
    [ $? == 0 ] && echo "${line} boot successed." || echo "${line} boot failed." 
    sleep 2
done
