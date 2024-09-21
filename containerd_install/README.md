# desc

install containerd, runc, crictl and nerdctl.

## downlaod containerd

* https://containerd.io/downloads/
    * example: `wget https://github.com/containerd/containerd/releases/download/v1.7.13/containerd-1.7.13-linux-amd64.tar.gz`


## download crictl

* https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md
    * example: 'wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.26.0/crictl-v1.26.0-linux-amd64.tar.gz'


## download nerdctl

```bash
wget https://github.com/containerd/nerdctl/releases/download/v1.7.5/nerdctl-1.7.5-linux-amd64.tar.gz

```

## doaneload runc

such as
```bash
wget https://github.com/opencontainers/runc/releases/download/v1.2.0-rc.2/runc.amd64
```


# examples


```yaml

- hosts: 192.168.1.1
  vars:
    ansible_soft_dir: /data/soft/ansible
    containerd_packet: '{{ansible_soft_dir}}/containerd/containerd-1.7.21-linux-amd64.tar.gz'
    containerd_data_dir: /data/data/containerd
    containerd_base_dir: /data/server/containerd
    containerd_install_dir: /data/server/{{containerd_packet_dir_name}}
    cni_packet: '{{ansible_soft_dir}}/containerd/cni-plugins-linux-amd64-v1.5.1.tgz'
    runc_packet: '{{ansible_soft_dir}}/containerd/runc.amd64'
    crictl_packet: '{{ansible_soft_dir}}/containerd/crictl-v1.26.0-linux-amd64.tar.gz'
    nerdctl_packet: '{{ansible_soft_dir}}/containerd/nerdctl-1.7.6-linux-amd64.tar.gz'
  roles:
  - containerd_install
  - cni_install
```
