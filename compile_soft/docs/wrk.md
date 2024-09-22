# desc

wrk 依赖 luajit, 这里正好安装了 openresty, 所以就使用 openresty 的 luajit, 不过需要配置库路径。

```bash

# wget https://github.com/wg/wrk/archive/refs/tags/4.2.0.tar.gz

# cat /etc/ld.so.conf.d/luajit.conf 
/usr/local/openresty/luajit/lib

# ldconfig

# ln -sv /usr/local/openresty/luajit/include/luajit-2.1 /usr/include/luajit
‘/usr/include/luajit’ -> ‘/usr/local/openresty/luajit/include/luajit-2.1’

# make -j 4
# pwd
/data/apps/soft/ansible/wrk/wrk-4.2.0

```
