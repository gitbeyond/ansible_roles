#!/bin/bash
export PATH={{ ansible_env["PATH"] }}
device=$1
item=$2

string=$(/usr/bin/tail -n20 /tmp/iostat_output | grep "\b$device\b" | tail -1)
iostat_version=$(rpm -q sysstat |awk -F'.' '{print $3}' |awk -F'-' '{print $NF}')



case $item in
    rrqm)
        rrqm=$(echo $string |awk '{print $2}')
        echo "$rrqm"
        ;;
    wrqm)
        wrqm=$(echo $string |awk '{print $3}')
        echo "$wrqm"
        ;;
     rps)
        rps=$(echo $string |awk '{print $4}')
        echo "$rps"
        ;;
     wps)
        wps=$(echo $string |awk '{print $5}')
        echo "$wps"
        ;;
    rwps)
        rps=$(echo $string |awk '{print $4}')
        wps=$(echo $string |awk '{print $5}')
        rwps=$(echo "scale=3;${rps}+${wps}" |bc)
        echo "${rwps}"
       ;;
    rKBps)
        rkbps=$(echo $string |awk '{print $6}')
        echo "$rkbps"
        ;;
    wKBps)
        wkbps=$(echo $string |awk '{print $7}')
        echo "$wkbps"
        ;;
    rwKBps)
        rkbps=$(echo $string |awk '{print $6}')
        wkbps=$(echo $string |awk '{print $7}')
        rwkbps=$(echo "scale=3;${rkbps}+${wkbps}" |bc)
        echo "${rwkbps}"
        ;;
    avgiosize):
        rkbps=$(echo $string |awk '{print $6}')
        wkbps=$(echo $string |awk '{print $7}')
        rwkbps=$(echo "scale=3;${rkbps}+${wkbps}" |bc)
        avgiosize=$(if [ ${rwkbps} == "0" ];then
        		echo "0.00"
        	    else
        		echo "scale=3;${rwkbps}/${rwps}" |bc
        	    fi)
        echo "${avgiosize}"
       ;;
    avgrq_sz)
        avgrq_sz=$(echo $string |awk '{print $8}')
        echo "$avgrq_sz"
        ;;
    avgqu_sz)
       avgqu_sz=$(echo $string |awk '{print $9}')
       echo "$avgqu_sz"
        ;;
    await)
       await=$(echo $string |awk '{print $10}')
       echo "$await"
        ;;
    svctm)
       if [[ ${iostat_version} == 20 ]];then
           svctm=$(echo $string |awk '{print $11}')
           echo "$svctm"
       else
           svctm=$(echo $string |awk '{print $13}')
           echo "$svctm"
       fi
        ;;
    util)
       if [[ ${iostat_version} == 20 ]];then
           util=$(echo $string |awk '{print $12}')
           echo "$util"
       else
           util=$(echo $string |awk '{print $14}')
           echo "$util"
       fi
        ;;
    wdata_size)
        wkbps=$(echo $string |awk '{print $7}')
        wps=$(echo $string |awk '{print $5}')
    	if [ $wps == "0.00" ];then
    	    echo "0"
    	else
    	    echo "scale=3;$wkbps/$wps" |bc
    	fi
        ;;
    rdata_size)
        rps=$(echo $string |awk '{print $4}')
        rkbps=$(echo $string |awk '{print $6}')
    	if [ $rps == "0.00" ];then
    	    echo "0"
    	else
    	    echo "scale=3;$rkbps/$rps" |bc
    	fi

        ;;
    *)
    	echo "usage $1:device  $2:io_mode"
        ;;
esac
