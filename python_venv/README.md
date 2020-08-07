
# role desc
* date: 2020/08/05

python 的项目不同于 java 或者 nodejs 的前端项目，需要依照 requirement.txt 进行安装依赖包(目前一般是这种方式，虽然有一种 pipenv的方式，但是极度不成熟，根本没法用)，而安装包的操作应该是缓存下来的，不应该每次都重新安装包(有些依赖多的时候，十分耗时，且没有每次都安装的必要)，目前的想法是基于某个 python 包，比如 /usr/bin/python3 生成一个env,然后使用这个 env 中的 pip 来安装依赖。最后将这个包copy 当镜像或者远程机器上（这个 env 的 base 包个人认为也应该存在，这个目前并不十分确定）。

```bash
# /usr/bin/python3 -m venv /data/apps/opt/bert-env
# 设置 pip 需要的环境变量,如果需要的话
# 
# /data/apps/opt/bert-env/bin/pip install -r requirement.txt

```
这里有一个问题，就是 Dockerfile 构建的时候的文件必须在构建的目录当中
比如在 `/data/apps/soft/ansible/docker_build/bert-es-search` 中进行构建
需要 copy 这个 bert-env 目录，那么这个目录必须在 `/data/apps/soft/ansible/docker_build/bert-es-search` 下才行，且不能是软链接
那么这就有了两种选择
* 将 venv 建在 `/data/apps/soft/ansible/docker_build/bert-es-search` 中，copy 至镜像 `/data/apps/soft/ansible/docker_build/bert-es-search/bert-env` 处，然后为其做软链接指向一个通用路径如 `/data/apps/opt/bert-env`
* 将 venv 建在 `/data/apps/opt/bert-env` 处，然后将其 mv 至 `/data/apps/soft/ansible/docker_build/bert-es-search`,再在原位置建立软链接指向此处，`/data/apps/opt/bert-env` -> `/data/apps/soft/ansible/docker_build/bert-es-search/bert-env`, copy 至镜像或复制到远程机器的时候直接放到 `/data/apps/opt/bert-env` 就行


如果是部署到远程机器，如何将其部署至远程机器是一个问题，默认的 ansible 的操作是比较慢的，甚至有时候会卡死，之前部署几G的anaconda.tgz 包时遇到过这个问题。不行的话，就得写脚本来做，几百M 的话，就压缩了，使用 unarchive 模块来操作应该是没有问题的。

当然这种操作也可以直接在远程机器上并行操作，反正一般来说一个 env 他所依赖的包也不会经常改动。


pip 模块可以创建 venv，不过不能指定 venv 的参数，此处暂不用其实现。


## examples
```yaml
- hosts: localhost
  vars:
    - project_venv_packets:
        - django==2.0.2
    - project_venv_path: /opt/mydjango
    - project_venv_args: '--copies'
    - project_venv_pip_tmpdir: /tmp
    - project_docker_work_dir: /docker/docker_build/mydjango
  roles:
    - { role: python_venv}

# 
- hosts: 10.111.32.181
  vars:
    - project_venv_packets:
        - django==2.0.2
    - project_venv_path: /opt/myflask
    - project_venv_args: '--copies'
    - project_venv_pip_tmpdir: /data/apps/tmp/pip
  roles:
    - { role: python_venv}

```
# 注意
1. python 的环境需要事先存在，本 role 没有安装 python 的操作。
