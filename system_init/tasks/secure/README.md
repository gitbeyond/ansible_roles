# test

密码强度测试
```bash
[root@nano-kvm-13 ~]# passwd test1
Changing password for user test1.
New password: abc123,./
BAD PASSWORD: The password contains less than 1 uppercase letters
New password: abc123E,
BAD PASSWORD: The password fails the dictionary check - it is too simplistic/systematic
New password: 

[root@nano-kvm-13 ~]# passwd test1
Changing password for user test1.
New password: 8ea7e63eT#
Retype new password: 8ea7e63eT#
passwd: all authentication tokens updated successfully.
```




ssh登录失败尝试
```bash
Feb 15 18:51:02 nano-kvm-13 sshd[22747]: pam_tally2(sshd:auth): user test1 (1001) tally 7, deny 3
Feb 15 18:51:04 nano-kvm-13 sshd[22747]: Failed password for test1 from 10.6.36.11 port 47720 ssh2
```
pam_tally2 can unlock the user.
```bash
pam_tally2 --user test1 --reset
```

# centos6 test
```bash
[root@biyaotest yum.repos.d]# passwd test1
Changing password for user test1.
New password: abc123
BAD PASSWORD: it is too simplistic/systematic
New password: abc123,./
BAD PASSWORD: it is too simplistic/systematic
New password: abc123E,
BAD PASSWORD: it is too simplistic/systematic
passwd: Have exhausted maximum number of retries for service

[root@biyaotest yum.repos.d]# passwd test1
Changing password for user test1.
New password: 8ea7e63eT#
Retype new password: 8ea7e63eT#
passwd: all authentication tokens updated successfully.

```

login test
```bash
[root@nano-kvm-11 secure]# ssh test1@192.168.99.37
test1@192.168.99.37's password: 
[test1@biyaotest ~]$ ls
[test1@biyaotest ~]$ exit
logout
Connection to 192.168.99.37 closed.
[root@nano-kvm-11 secure]# sshpass -p 8ea7e63eT#1 ssh test1@192.168.99.37
Permission denied, please try again.
[root@nano-kvm-11 secure]# sshpass -p 8ea7e63eT#1 ssh test1@192.168.99.37
Permission denied, please try again.
[root@nano-kvm-11 secure]# sshpass -p 8ea7e63eT#1 ssh test1@192.168.99.37
Permission denied, please try again.
[root@nano-kvm-11 secure]# sshpass -p 8ea7e63eT#1 ssh test1@192.168.99.37
Permission denied, please try again.
```
锁定以后，即使使用正确的密码，也不能正常登录。
faillock 命令可以看到相关信息。
```bash
[root@biyaotest yum.repos.d]# faillock 
test1:
When                Type  Source                                           Valid
2022-02-22 11:52:40 RHOST 10.6.36.11                                           V
2022-02-22 11:52:45 RHOST 10.6.36.11                                           V
2022-02-22 11:52:49 RHOST 10.6.36.11                                           V
```
使用`--reset`可以重置失败的次数。然后就可以使用正确密码，重新登录。
```bash
[root@biyaotest yum.repos.d]# faillock --user test1 --reset
[root@biyaotest yum.repos.d]# faillock 
test1:
When                Type  Source                                           Valid
```
