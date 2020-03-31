uid_min=`(egrep -v ^# /etc/login.defs |egrep "^UID_MIN"|awk '($1="UID_MIN"){print $2}')` 
uid_max=`(egrep -v ^# /etc/login.defs |egrep "^UID_MAX"|awk '($1="UID_MAX"){print $2}')` 
egrep -v "oracle|sybase|postgres|informix" /etc/passwd|awk -F: '($3>='$uid_min' && $3<='$uid_max') {print $1":"$3}' 
result=`egrep -v "oracle|sybase|postgres|informix" /etc/passwd|awk -F: '($3>='$uid_min' && $3<='$uid_max') {print $1":"$3}'|wc -l`
echo "result="`egrep -v "oracle|sybase|postgres|informix" /etc/passwd|awk -F: '($3>='$uid_min' && $3<='$uid_max') {print $1":"$3}'|wc -l`

if [ ${result} -ge 1 ];then
    exit 0
else
    exit 1
fi

