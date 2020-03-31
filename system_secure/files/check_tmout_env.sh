
cat /etc/profile |egrep -v "^[[:space:]]*#"|egrep -v "^$"|egrep -i "TMOUT="|tail -1
