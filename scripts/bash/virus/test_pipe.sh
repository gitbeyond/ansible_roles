
echo $$
mypid=$$
ps -ef |grep -v grep |grep $$
myppid=$(ps -ef |grep -v grep |grep $$ |awk -vpid=${mypid} '{if($2==pid){print $3}}')
ps -ef |grep -v grep |grep ${myppid}

mypppid=$(ps -ef |grep -v grep |grep ${myppid} |awk -vpid=${myppid} '{if($2==pid){print $3}}')
ps -ef |grep -v grep |grep ${mypppid}

pipe_input=$(while read line;do
    if [ -z "${line}" ];then
        break
    else 
        echo "${line}"
    fi  
done &)

echo ${pipe_input}
