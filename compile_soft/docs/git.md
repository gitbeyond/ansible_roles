# desc

## centos

编译时，需要安装如下的包，否则会报错`git: 'remote-https' is not a git command. See 'git --help'.`。

另外，需要将安装目录下的`libexec/git-core`也加入`PATH`。
```bash
yum install libcurl-devel
```


编译命令
```bash
# ./configure --prefix=/data/apps/opt/git-2.34.5
# make -j $(nproc)
# make install
```
