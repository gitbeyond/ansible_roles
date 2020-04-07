	gid_min=`(egrep -v ^# /etc/login.defs |egrep "^GID_MIN"|awk '($1="GID_MIN") {print $2}')` 
gid_max=`(egrep -v ^# /etc/login.defs |egrep "^GID_MAX"|awk '($1="GID_MAX") {print $2}')` 
egrep -v "oracle|sybase|postgres|informix" /etc/passwd|awk -F: '($4>='$gid_min' && $4<='$gid_max') {print $1":"$3":"$4}' 
echo $gid_min $gid_max 
echo "result="`egrep -v "oracle|sybase|postgres|informix" /etc/passwd|awk -F: '($4>='$gid_min' && $4<='$gid_max') {print $1":"$3":"$4}'|wc -l` 
unset gid_min gid_max
