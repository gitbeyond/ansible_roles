cat /etc/pam.d/su|egrep -v "^[[:space:]]*#"|egrep -v "^$"|egrep "^auth" 
