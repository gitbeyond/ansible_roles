cat /etc/hosts.allow |sed '/^#/d'|sed '/^$/d'|egrep -i "all|sshd|telnet" 
cat /etc/hosts.deny |sed '/^#/d'|sed '/^$/d'|egrep -i ":all"|egrep -i "all|sshd|telnet"
echo "allowno="`egrep -i "sshd|telnet|all" /etc/hosts.allow |sed '/^#/d'|sed '/^$/d'|wc -l` 
echo "denyno="`egrep -i "sshd|telnet|all" /etc/hosts.deny |egrep -i ":all" |sed '/^#/d'|sed '/^$/d'|wc -l`
