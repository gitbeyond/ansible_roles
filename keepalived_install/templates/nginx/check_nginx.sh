#!/bin/bash
export PATH={{ansible_env.PATH}}

#curl_cmd=/opt/.bakcurl
curl_cmd=/usr/bin/curl


systemctl status nginx
nginx_state=$?
${curl_cmd} http://127.0.0.1 -o /dev/null 2> /dev/null
curl_state=$?

if [[ ${nginx_state} == 0 && ${curl_state} == 0 ]];then
    exit 0
else
    exit 17
fi
