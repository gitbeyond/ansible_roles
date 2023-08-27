# haproxy

```bash
$ yum -y install systemd-devel
$ wget https://www.haproxy.org/download/2.7/src/haproxy-2.7.2.tar.gz
$ make -j 4 TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_SYSTEMD=1
$ make install PREFIX=/data/apps/opt/haproxy-2.7.2
$ ls /data/apps/opt/haproxy-2.7.2
doc  sbin  share
$ ls /data/apps/opt/haproxy-2.7.2/sbin/
haproxy

$ pwd
/data/apps/opt
$ tar zcf haproxy-2.7.2-centos7-binary.tar.gz haproxy-2.7.2


```

## 2.8 example

```bash
$ # make -j 4 TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_PCRE_JIT=1 USE_THREAD=1 USE_LUA=1 USE_OPENSSL_WOLFSSL=1 USE_ENGINE=1 USE_TFO=1 USE_NS=1 USE_PROMEX=1 USE_SYSTEMD=1
$ make -j 4 TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_PCRE_JIT=1 USE_THREAD=1 USE_ENGINE=1 USE_TFO=1 USE_NS=1 USE_PROMEX=1 USE_SYSTEMD=1
$ make install PREFIX=/data/apps/opt/haproxy-2.8.2

```


## make help

* the command print all options for make command
