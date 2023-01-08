# 安装uwsgi报错

```bash
      gcc: error: /data/apps/opt/miniconda3/lib/python3.9/config-3.9-x86_64-linux-gnu/libpython3.9.a: No such file or directory
      *** error linking uWSGI ***
      [end of output]
  
  note: This error originates from a subprocess, and is likely not a problem with pip.
error: legacy-install-failure

× Encountered error while trying to install package.
╰─> uwsgi

note: This is an issue with the package mentioned above, not pip.
hint: See above for output from the failure.

```

* https://zhuanlan.zhihu.com/p/497055461 : Linux安装uwsgi（centos7）
* https://uwsgi-docs.readthedocs.io/en/latest/Download.html : Getting uWSGI

# 安装gunicorn

```bash
[root@wanghaifeng-test miniconda3]# pip install gunicorn
Looking in indexes: https://pypi.tuna.tsinghua.edu.cn/simple
Collecting gunicorn
  Using cached https://pypi.tuna.tsinghua.edu.cn/packages/e4/dd/5b190393e6066286773a67dfcc2f9492058e9b57c4867a95f1ba5caf0a83/gunicorn-20.1.0-py3-none-any.whl (79 kB)
Requirement already satisfied: setuptools>=3.0 in /export/data/apps/opt/ansible6/lib/python3.9/site-packages (from gunicorn) (58.1.0)
Installing collected packages: gunicorn
Successfully installed gunicorn-20.1.0

```


启动服务
```bash
[root@wanghaifeng-test ansible-runner-service]# gunicorn -b 0.0.0.0:8000  --worker-connections=1000 --workers=3 wsgi:application 
[2023-01-07 20:41:44 +0800] [25817] [INFO] Starting gunicorn 20.1.0
[2023-01-07 20:41:44 +0800] [25817] [INFO] Listening at: http://0.0.0.0:8000 (25817)
[2023-01-07 20:41:44 +0800] [25817] [INFO] Using worker: sync
[2023-01-07 20:41:44 +0800] [25818] [INFO] Booting worker with pid: 25818
[2023-01-07 20:41:44 +0800] [25819] [INFO] Booting worker with pid: 25819
[2023-01-07 20:41:44 +0800] [25820] [INFO] Booting worker with pid: 25820
Analysing runtime overrides from environment variables
No configuration settings overridden
Logging configuration file (/etc/ansible-runner-service/logging.yaml) not found, using basic logging
Run mode is: prod
SSH keys present in /usr/share/ansible-runner-service/env
Analysing runtime overrides from environment variables
No configuration settings overridden
Logging configuration file (/etc/ansible-runner-service/logging.yaml) not found, using basic logging
Run mode is: prod
SSH keys present in /usr/share/ansible-runner-service/env
Analysing runtime overrides from environment variables
No configuration settings overridden
Logging configuration file (/etc/ansible-runner-service/logging.yaml) not found, using basic logging
Run mode is: prod
SSH keys present in /usr/share/ansible-runner-service/env
```


浏览器访问`http://172.25.0.14:8000/api`, 就可以看到api文档了

# 配置文件

* 在`runner_service/configuration.py`中，其配置文件默认为`/etc/ansible-runner-service/config.yaml`
    * 目前没发现，如何指定其他路径
    * 貌似可以通过环境变量进行覆盖


## 通过环境变量设置新的配置文件
```bash
[root@wanghaifeng-test ansible-runner-service]# export config_file=/tmp/config.yaml
[root@wanghaifeng-test ansible-runner-service]# gunicorn   --worker-connections=1000 --workers=3 wsgi:application 
[2023-01-07 21:13:30 +0800] [27568] [INFO] Starting gunicorn 20.1.0
[2023-01-07 21:13:30 +0800] [27568] [INFO] Listening at: http://127.0.0.1:8000 (27568)
[2023-01-07 21:13:30 +0800] [27568] [INFO] Using worker: sync
[2023-01-07 21:13:30 +0800] [27570] [INFO] Booting worker with pid: 27570
[2023-01-07 21:13:30 +0800] [27571] [INFO] Booting worker with pid: 27571
[2023-01-07 21:13:30 +0800] [27572] [INFO] Booting worker with pid: 27572
Analysing local configuration options from /etc/ansible-runner-service/config.yaml
/data/apps/soft/ansible/ansible/ansible-runner-service/runner_service/configuration.py:109: YAMLLoadWarning: calling yaml.load() without Loader=... is deprecated, as the default Loader is unsafe. Please read https://msg.pyyaml.org/load for full details.
  local_config = yaml.load(_cfg.read())
- setting port to 5001
- setting ip_address to 0.0.0.0
- setting target_user to root
Analysing runtime overrides from environment variables
- setting config_file to /tmp/config.yaml

```

其他常用的环境变量
* `export logging_conf=/data/apps/conf/ansible-runner-service/logging.yaml`


# 安装总结

目前来看，`runner-service`就是一个使用`flask`框架编写的`web`应用，且不需要数据库等额外组件的支持，只要为其指定`ansible`相关的工作目录即可。

证书方面，也是为了让`nginx`配置一个证书，然后在入口处变成`https`,`nginx`与`runner-service`通信还是使用的`http`或者`uwsgi`协议。

所以，基于此，安装`runner-service`,可以使用如下步骤:
1. 先把`ansible`环境(`venv`或其他虚拟环境)安装好，其中要包括`ansible-runner`
    * 在源码的`Dockerfile`中，其指定了`ansible-runner==1.4.6`，这个不知道是否是强依赖
2. 安装`runner-service`需要的库
    * yum
        * wget
        * unzip
        * pexpect
    * pip
        * flask
        * flask-restful
        * gunicorn (官方的示例是uwsgi)
        * psutil
        * docutils
        * pyOpenSSL
        * netaddr ?
        * notario ?
3. 安装`ansible-runner-service`的源码，从github上下载的`tar.gz`包
3. 生成配置文件
    * runner-service 的配置文件
        * 可以同时使用环境变量
    * gunicorn 的配置文件
        * 仅用命令行也可以
4. 启动服务(目前使用`supervisor`来管理)
    * 用不用`nginx`, 视具体情况而定


使用本role之后，就可以尝试启动服务了
```bash
$ export config_file=/data/apps/conf/ansible-runner-service/config.yaml
$ export logging_conf=/data/apps/conf/ansible-runner-service/logging.yaml
# 这个变量设置在配置文件中好像不生效
$ export playbooks_root_dir=/data/apps/data/wanghaifeng/ansible
[root@wanghaifeng-test ansible-runner-service]# pwd
/data/apps/conf/ansible-runner-service

[root@wanghaifeng-test ansible-runner-service]# gunicorn -c gunicorn.py wsgi:application
```


# 安装包的下载
```bash
wget https://github.com/ansible/ansible-runner-service/releases/download/1.0.7/ansible-runner-service-1.0.7.tar.gz
```

# 待办
1. ansible的环境虽然可以直接生成，但是目前的情况，一般都跟ansible的工作目录（源码）有关联
    * 通过源码中的`requirements.txt`，比单纯的部署一个`venv`要更友好
    * 当然部署源码之前也需要把`ansible`的`venv`部署好;
