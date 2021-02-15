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

# 问题
1. 获取包名这里有问题，包名不存在时，不会停止
2. 使用普通用户启动 nano 报错
```bash
[nano@P-111-15 ~]$ /data/apps/opt/nano-cell/cell start
bridge br0 is ready
default route ready
start cell fail: listen on DHCP port fail, please disable dnsmasq or other DHCP service.
message: listen udp :67: bind: permission denied

```
3. 被控节点开启了 `Defaults    requiretty`
    * https://github.com/ansible/ansible/pull/13487 : Make sudo+requiretty and ANSIBLE_PIPELINING work together
    * https://stackoverflow.com/questions/35597076/ansible-sudo-sorry-you-must-have-a-tty-to-run-sudo
    * https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html : ansible.builtin.ssh – connect via ssh client binary
    * https://docs.ansible.com/ansible/latest/reference_appendices/config.html: Ansible Configuration Settings

# install_qga.yml 是一个单独的playbook，是用来为vm安装 qga 的，使用时单独引用即可
```yaml
- name: install qemu-guest-agent
  hosts: myvm
  tasks:
    - name: import qemu-ga tasks
      include_tasks: /home/wanghaifeng/wanghaifeng/ansible_roles/nano_install/tasks/qga_install/qga_install.yml
      when: 
        - ansible_virtualization_type == 'kvm'
        - ansible_virtualization_role == 'guest'
```
