#!/bin/bash
# 2018/09/27
# author: gitbeyond
#
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

basedc='dc=test,dc=com'
max_gid=$(ldapsearch -x -LLL -b"${basedc}" 'gidNumber'  |grep -i gidnumber |awk '{print $2}' | sort -n |tail -n 1)
add_gid=$[max_gid+1]
groupname=${1}
displayname=${1}
admin_user="cn=admin,${basedc}"
admin_pass='ldappass'
ldif_dir=./ldif


ldif_template="\
dn: cn=${groupname},ou=Group,${basedc}
objectClass: posixGroup
objectClass: top
cn: ${groupname}
gidNumber: ${add_gid}"
usage(){
    echo "$0 group_name"
}
# 判断 ${groupname} 是不为空的话
if [ -n "${groupname}" ];then
    :
else
    usage
    exit 5
fi

ldapsearch -x -LLL -b"ou=Group,${basedc}" cn=${groupname} |grep gid &> /dev/null
group_stat=$?
if [ ${group_stat} == 0 ];then
    echo "the ${groupname} group already exist."
    exit 6
else
    #ldapadd -x -D "${admin_user}" -w "${admin_pass}" -f ${groupname}.ldif
#    echo ${ldif_template} > ${groupname}.ldif
    # 生成 ldif 文件
    cat << EOF > ${ldif_dir}/${groupname}_group.ldif
${ldif_template}
EOF
    # 执行添加操作 
    ldapadd -x -D "${admin_user}" -w "${admin_pass}" -f ${ldif_dir}/${groupname}_group.ldif
    # 打印 gidNumber, add_user 的脚本调用时获取此 gid
    echo ${add_gid}
fi
