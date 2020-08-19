[toc]
# 20200807 role desc

这个 role 是根据 Dockerfile 来构建 docker 镜像的。

bert-serving 项目时创建，之间是用脚本。

但是这个 role 怎么用，还没有想好,因为在步骤上来说跟 `deploy_project` 是有很多重合之处的。

初步来说会把这个 role 的功能替代 `deploy_project` 中的 docker 构建镜像的步骤。

这个更方便，更优雅，更符合要求。


# role test

1. example 1
dockerfile
```bash
# cat Dockerfile
FROM centos:centos7
MAINTAINER wanghaifeng <haifengsss@geotmt.com>

LABEL name="CentOS7 with httpd"

RUN yum install -y httpd
```

playbook
```yaml
- hosts: localhost
  vars:
    - project_docker_registry_addr: 'test-harbor.mydomain.com'
    - project_docker_registry_user: 'user1'
    - project_docker_registry_pass: 'user1_pass'
    - project_docker_image_name: testimage
    - project_docker_image_repo: library
    - project_dockerfile: Dockerfile
    - project_docker_work_dir: /docker/testimage
  roles:
    - { role: docker_image}
```

这样构建后的镜像，在第二次构建时不会重新构建，只是新加了一个 tag 而已。

2. example 2
dockerfile
```bash
# cat templates/Dockerfile 
FROM centos:centos7
MAINTAINER wanghaifeng <haifengsss@163.com>

LABEL name="CentOS7 with python3 and django"

COPY mydjango /opt/mydjango
```
playbook
```yaml
- hosts: localhost
  vars:
    - project_docker_registry_addr: 'test-harbor.mydomain.com'
    - project_docker_registry_user: 'user2'
    - project_docker_registry_pass: 'user2_pass'
    - project_docker_image_name: mydjango
    - project_docker_image_repo: library
    - project_dockerfile: Dockerfile
    - project_docker_work_dir: /docker/mydjango
  roles:
    - { role: docker_image}
```

这个测试更接近于之间的一个项目，当 mydjango 中的内容没有变化时，是不会进行真正的构建的，文件时间的变化，也不会真正执行构建。
只是添加了一个 tag。

当没有指定 `project_docker_registry_addr` 而 `docker_image` 的 `push` 参数设置为 `false` 时,
状态竟然是 changed `"Built image library/mydjango:v20200807160141 from /docker/mydjango"`,
但是查看镜像时，发现也只是添加了一个 tag 而已
```bash
[root@docker-182 boot_project]# docker images |grep django
mydjango                                                         v20200807160141     17d0657b2419        5 hours ago         265MB
test-harbor.geotmt.com/library/mydjango                          v20200807111407     17d0657b2419        5 hours ago         265MB
test-harbor.geotmt.com/library/mydjango                          v20200807111601     17d0657b2419        5 hours ago         265MB
test-harbor.geotmt.com/library/mydjango                          v20200807111734     17d0657b2419        5 hours ago         265MB
test-harbor.geotmt.com/library/mydjango                          v20200807111115     0049bc6dea01        5 hours ago         265MB
test-harbor.geotmt.com/library/mydjango                          v20200807111305     0049bc6dea01        5 hours ago         265MB
```

再次执行时，依然是 changed, 现在可以得出一个结论，
* 当 push 为 true, 且只是更新 tag 时，那么 changed 为 false.
* 当 push 为 false 时，更新 tag 的操作也会导致 changed 为 true.



# issue

1. 当前默认使用时间来当作tag, 在没有进行实际的 build 时，会在原来的镜像基础上添加新的 tag, 并且会 push 到 registry 上（如果指定了 registry 的话）。
2. Dockerfile 中 FROM 的镜像如果带了 registry 的 url, 那么必须已经 push 到 registry 中
