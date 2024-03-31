# desc


编写脚本，生成硬件`raid`的物理磁盘的健康数据。

# 参考

* https://phoenixnap.com/kb/how-to-set-up-hardware-raid-megacli : 安装 megacli 
* https://www.broadcom.com/support/download-search?dk=megacli : 软件网站

# 支持的监控系统

## prom

将数据写入`node_exporrer`的`--collector.textfile.directory=""`指定的目录当中。
同时需要开启`--collector.textfile`, 这个默认就是开启的。

为`node_exporter`配置`hostPath`
```bash
# diff node-exporter-daemonset.yaml new/node-exporter-daemonset.yaml 
34a35
>         - --collector.textfile.directory=/host/root/data/apps/data/node_exporter/textfile
52a54,56
>         - mountPath: /data/apps/data/node_exporter/textfile
>           name: data
>           readOnly: true
96a101,104
>       - hostPath:
>           path: /data/apps/data/node_exporter/textfile
>           type: DirectoryOrCreate
>         name: data

```

如果一个`hostPath`的`volume`没有被挂载到某个`container`之上，那么，其就不会被创建（如果其类型为`DirectoryOrCreate`的话）。

## examples

```yaml
- hosts: k8s_node
  vars:
    raid_megacli_rpm_package: '/data/apps/soft/ansible/megacli/Linux/MegaCli-8.07.14-1.noarch.rpm'
  roles:
    - {role: raid_monitor}
```


# megacli 生成的信息

* Firmware state: Online, Spun Up
* Drive Temperature :35C (95.00 F)

* Port status: Active
  * 这个有两个port,闹不清啥意思
* Device Speed: 12.0Gb/s 
* Link Speed: 12.0Gb/s
  

# 判断是否跳过主机

vmware虚拟机中的信息
```
"ansible_product_name": "VMware Virtual Platform",
"ansible_system_vendor": "VMware, Inc.",
"ansible_virtualization_tech_guest": [
            "VMware"
        ],
"ansible_virtualization_type": "VMware",
"ansible_virtualization_role": "guest",
```

物理机中的信息
```
"ansible_product_name": "PowerEdge R630",
"ansible_system_vendor": "Dell Inc.",
"ansible_virtualization_tech_host": [
            "kvm"
        ],
        "ansible_virtualization_type": "kvm",
"ansible_virtualization_role": "host",
```

# node_exporter 自带的 `node_md_disks`

这个是采集`/proc/mdstat`内的信息，此信息应该是由`mdadm`工具创建的软`raid`设备。
