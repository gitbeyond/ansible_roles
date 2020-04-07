cat /etc/login.defs |egrep -v "^[[:space:]]*#"|egrep -E '^\s*PASS_MAX_DAYS|^\s*PASS_MIN_DAYS|^\s*PASS_WARN_AGE'
cat /etc/login.defs |grep -v "^[[:space:]]*#"|grep -E '^\s*PASS_MAX_DAYS|^\s*PASS_MIN_DAYS|^\s*PASS_WARN_AGE'
