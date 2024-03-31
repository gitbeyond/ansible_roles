#!/bin/bash 
SEND_THREAD_NUM=13 
tmp_fifofile="/tmp/$$.fifo" 
mkfifo "$tmp_fifofile" 
# 新建一个随机fifo管道文件 
exec 6<>"$tmp_fifofile"
rm $tmp_fifofile 

for ((i=0;i<$SEND_THREAD_NUM;i++));do 
    echo 
done >&6 

for i in `seq 100`;do 
    read -u6
    { 
        echo $i 
        sleep 3 
        echo >&6 
    } &
    pid=$! 
    echo $pid 
done 
wait
exec 6>&- 
exit 0 
