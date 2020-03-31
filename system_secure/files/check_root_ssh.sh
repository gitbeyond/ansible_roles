#!/bin/bash
if egrep -v "^[[:space:]]*#" /etc/ssh/sshd_config|egrep -i "PermitRootLogin (no)|(without-password)|(prohibit-password)|(forced-commands-only)";then 
    echo "Do not permit root login by ssh,check result:true";
    root_login_stat=0
else
    echo "Permits root login by ssh,check result:false";
    root_login_stat=1
fi

if egrep  -v "^[[:space:]]*#" /etc/ssh/sshd_config|egrep -i "^[[:space:]]*protocol[[:space:]]*2|^[[:space:]]*Protocol[[:space:]]*2";then 
    echo "SSH2,check result:true"
    ssh_protocol=0
else
    echo "not SSH2,check result:false"
    ssh_protocol=1

fi

if [ ${root_login_stat} == 0 ] && [ ${ssh_protocol} == 0 ];then
    exit 0
else
    exit 1
fi
