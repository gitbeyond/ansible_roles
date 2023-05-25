# desc
example:

```yaml
- hosts: 172.16.1.1
  roles:
    - { role: docker_install, 
        docker_src_conf: docker/daemon.json,
        docker_src_service_conf: docker/docker.service,
        docker_packet: "{{packet_base_dir}}/docker-19.03.0.tgz"}

```

```yaml
- hosts: 172.27.1.1
  vars:
    app_base_dir: /opt/server
    docker_base_dir: /opt/server/docker
    docker_data_dir: /opt/data/docker
    docker_conf_dir: /etc/docker
    docker_src_conf: '{{playbook_dir}}/templates/daemon.json'
    docker_src_service_conf: '{{playbook_dir}}/templates/docker.service'
  roles:
  - role: docker_install
    docker_packet: "/opt/server/docker-20.10.9.tar.gz
```
# todo

* add clean_image.sh to cron job
