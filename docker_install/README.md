example:

```yaml
- hosts: 172.16.1.1
  roles:
    - { role: docker_install, 
        docker_src_conf: docker/daemon.json,
        docker_src_service_conf: docker/docker.service,
        docker_packet: "{{packet_base_dir}}/docker-19.03.0.tgz"}
```
