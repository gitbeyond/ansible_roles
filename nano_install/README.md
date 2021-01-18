# 作用
这个role的作用是部署nano集群。

nano 分为 core, cell, frontend 三个组件。

* core 是主控端。
* cell 是被控端。
* frontend 是前端进程。

这里可以为host指定 `nano_role` 的变量来决定其部署为哪种角色。(还没有实现)
目前主要是部署cell.

## examples

```yaml
# group_vars/nano_cell.yml

## nano core 的实际ip地址
nano_core_ph_ip: 10.111.32.182
## nano core 的vxlan ip
nano_core_vxlan_ip: 172.16.5.182
## nano 通信时的组播地址
nano_multicast_address: 224.0.0.226
nano_packet: /data/apps/soft/ansible/nano/nano-cell-1.3.0.tgz
nano_confs:
  - domain.cfg

- hosts: nano_cell
  roles:
  - {role: nano_install}

```
