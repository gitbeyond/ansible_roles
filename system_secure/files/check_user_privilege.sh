ls -lL /etc/passwd 2>/dev/null 
echo "passwd_count="`ls -lL /etc/passwd 2>/dev/null|grep -v "[r-][w-]-[r-]--[r-]--"|wc -l` 
ls -lL /etc/group 2>/dev/null 
echo "group_count="`ls -lL /etc/group 2>/dev/null|grep -v "[r-][w-]-[r-]--[r-]--"|wc -l` 
ls -lL /etc/services 2>/dev/null 
echo "services_count="`ls -lL /etc/services 2>/dev/null|grep -v "[r-][w-]-[r-]--[r-]--"|wc -l` 
ls -lL /etc/shadow 2>/dev/null 
echo "shadow_count="`ls -lL /etc/shadow 2>/dev/null|grep -v "[r-]--------"|wc -l` 
ls -lL /etc/xinetd.conf 2>/dev/null 
echo "xinetd_count="`ls -lL /etc/xinetd.conf 2>/dev/null|egrep -v "[r-][w-]-------"|wc -l` 
ls -lLd /etc/security 2>/dev/null 
echo "security_count="`ls -lLd /etc/security 2>/dev/null|egrep -v "[r-][w-]-------"|wc -l`
