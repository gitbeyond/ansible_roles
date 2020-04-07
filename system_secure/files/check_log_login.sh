login_num=$(last | wc -l)

if [ ${login_num} -lt 1 ];then
    exit 1
fi
