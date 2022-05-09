[toc]

* doc_name: 202112 ldap 测试(云笔记中的旧名)
* date: 202112

# `36.13`部署ldap用于测试

```bash
[root@nano-kvm-13 ldap]# slapadd -n 0 -F /etc/openldap/slapd.d -l root.ldif 
slapadd: could not add entry dn="olcDatabase=mdb,cn=config" (line=1): autocreation of "olcDatabase={-1}frontend" failed
_#################### 100.00% eta   none elapsed            none fast!         
Closing DB...



```



修改root密码
```bash
[root@nano-kvm-13 ldap]# ldapadd -Y EXTERNAL -H ldapi:/// -f changepwd.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={0}config,cn=config"


[root@nano-kvm-13 ldap]# ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint1.ldif 
modifying entry "cn=module{0},cn=config"

[root@nano-kvm-13 ldap]# ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint2.ldif 
adding new entry "olcOverlay=refint,olcDatabase={2}hdb,cn=config"

```

# 12/14

## ldap测试

```bash
[root@nano-kvm-13 ~]# ldapsearch -x -LLL -H ldapi:/// 'cn=wanghaifeng'
dn: cn=wanghaifeng,ou=People,dc=by,dc=com
cn: wanghaifeng
objectClass: inetOrgPerson
objectClass: top
sn: wang
displayName:: 546L5rW35bOw
mail: wanghaifeng@idstaff.com

[root@nano-kvm-13 ~]# echo '546L5rW35bOw' |base64 -d
王海峰
```