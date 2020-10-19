
# 这个是临时检测哪个表 distcp 失败， rebuild 失败的脚本, 临时的命令，不太正规，只是实现了一个复杂的命令而已
cat dbs.txt_all |while read line; do 
    cd ${line}
    cat ${line}_tbs.txt |while read tb; do 
        if grep "${line}.${tb}" distcp_success.txt > /dev/null;then
            if grep "${line}.${tb}" distcp_failed.txt > /dev/null;then
                sed -i "/${line}.${tb}/d" distcp_failed.txt
            fi
        else
            echo ${line}.${tb}
        fi
    done
    cd -
done

cat dbs.txt_all |while read line; do 
    cd ${line}
    cat ${line}_tbs.txt |while read tb; do 
        if grep "${line}.${tb}" rebuild_table_success.txt > /dev/null;then
            if grep "${line}.${tb}" rebuild_table_failed.txt > /dev/null;then
                sed -i "/${line}.${tb}/d" rebuild_table_failed.txt
            fi
        else
            echo ${line}.${tb}
        fi
    done
    cd -
done
