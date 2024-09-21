# desc

install the cni.

containerd_install is dependent on this role .


# examples

```bash
# cd /data/soft/ansible/containerd
# wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
```


```yaml


- hosts: host1
  vars:
    ansible_soft_dir: /data/soft/ansible
    cni_packet: '{{ansible_soft_dir}}/containerd/cni-plugins-linux-amd64-v1.5.1.tgz'
  roles:
  - cni_install

```
