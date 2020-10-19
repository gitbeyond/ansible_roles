# 这也是个临时的脚本，只是把 failed 的表写到 tbs.txt 中，让主脚本把 failed 的表重试
dt=$(date +%Y%m%d%H%M%S)
cat dbs.txt_all | while read line;do
    cd ${line}
    if [ -f ${line}_tbs_all.txt ];then
        :
    else
 
        mv ${line}_tbs.txt ${line}_tbs_all.txt
    fi
    if [ -f distcp_failed.txt ];then
        awk -F. '{print $NF}' distcp_failed.txt > ${line}_tbs.txt
        #mv distcp_failed.txt ${dt}
    else
        :
    fi
    cd -

done
