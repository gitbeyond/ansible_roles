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
