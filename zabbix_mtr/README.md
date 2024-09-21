# desc

1. 添加一个计划任务，使用 mtr 监控目标地址
2. zabbix 使用脚本收集监控数据

# examples


```yaml
---
- hosts: 10.111.32.237
  remote_user: root
  roles:
    - role: zabbix_mtr
      zabbix_child_conf_dir: /etc/zabbix/zabbix_agentd.d
      zabbix_script_dir: /etc/zabbix 
      zabbix_agent_service_name: zabbix-agent
```

# zabbix template

## 自动发现规则 
mtr_hop_hosts  
宏名称： {#HOPHOST} {#CHECK_HOST} {#CHECK_TYPE} {#CHECK_PORT}
mtr_hop_hosts  

### template keys
status  整数 
loss    float
last    float
avg     float
wrst    float


```
mtr {#CHECK_TYPE} check {#HOPHOST} {#CHECK_HOST}:{#CHECK_PORT} status
mtr_check[{#HOPHOST},status,{#CHECK_TYPE},{#CHECK_PORT}]

mtr {#CHECK_TYPE} check {#HOPHOST} {#CHECK_HOST}:{#CHECK_PORT} loss
mtr_check[{#HOPHOST},loss,{#CHECK_TYPE},{#CHECK_PORT}]

mtr {#CHECK_TYPE} check {#HOPHOST} {#CHECK_HOST}:{#CHECK_PORT} avg
mtr_check[{#HOPHOST},avg,{#CHECK_TYPE},{#CHECK_PORT}]

mtr {#CHECK_TYPE} check {#HOPHOST} {#CHECK_HOST}:{#CHECK_PORT} wrst
mtr_check[{#HOPHOST},wrst,{#CHECK_TYPE},{#CHECK_PORT}]
```


# install mtr
```bash
# wget https://gitee.com/mirrors/mtr/repository/archive/v0.94.zip
# unzip v0.94.zip
# cd mtr-v0.94/

# ./bootstrap.sh
configure.ac:20: installing 'build-aux/config.guess'
configure.ac:20: installing 'build-aux/config.sub'
configure.ac:9: installing 'build-aux/install-sh'
configure.ac:9: installing 'build-aux/missing'
Makefile.am: installing 'build-aux/depcomp'
parallel-tests: installing 'build-aux/test-driver'

# ./configure --prefix=/usr/local/mtr-0.94
# make -j 4
# make install
```


# todo
mtr 脚本计划任务加个锁
