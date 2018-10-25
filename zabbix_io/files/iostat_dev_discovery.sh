#/bin/bash
#
#export PATH={{ ansible_env['PATH'] }}

iocmd=`which iostat`
parts=`$iocmd -d | awk '/[^$]/{print $1}' |grep -E -v "(Linux|Device)"`
last_p=$(echo $parts |awk '{print $NF}')


all_part=$(
for i in $parts;do
	if [ $i == ${last_p} ];then
		echo "{\"{#IOTYPE}\":\"$i\"}"
	else	
		echo "{\"{#IOTYPE}\":\"$i\"},"
	fi
done)
echo "{\"data\":[${all_part}]}"
