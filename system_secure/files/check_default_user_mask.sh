mask_value=$(cat /etc/login.defs|egrep -v "^[[:space:]]*#"|egrep -i umask|tail -n1|awk '{print $1":"$2}')

if [ ${mask_value} != "UMASK:077" ];then
    exit 1
fi
