# role 说明
这个role的作用是将编译好的 `nginx` 部署到远程机器上,最简单的使用方式如下，其他默认变量参考 `defaults/main.yml`


example:
```yaml
- hosts: 10.111.32.61
  remote_user: root
  roles:
    - { role: nginx_install,
        nginx_packet: /data/apps/soft/ansible/tengine-2.3.0_centos7_bin.tgz }
```

需要注意的几个变量:
* `nginx_confs`: 这个是一个列表，包含了nginx的配置文件，`dest_dir` 都是 `{{nginx_conf_dir}}` 这个目录，也就是说默认没有精细化的配置，安装后只是一个服务器，虚拟主机需要自己另行配置，默认包含 nginx.conf 和 htpasswd 这个 `stub_status` 模块的密码文件
* `nginx_install_method`: 当前只实现了 local 的方式, 会使用  yum 安装一些依赖包，比如 geoip-devel, 如果是在没网的环境中，编译的时候，酌情开启一些模块，这样依赖少，可以至少保证正常工作，那时请将这个变量的值设为 local, 这个 net 的安装操作暂未实现, 安装的依赖包是编译 nginx 依赖的包,可以自己指定，变量参见 `defaults/main.yml`


## nginx 的编译参数
这里使用了 tengine 的源码，并且添加了额外的 `/usr/src/nginx-module-vts` 模块
```bash
# /data/apps/opt/nginx/sbin/nginx -V
Tengine version: Tengine/2.3.2
nginx version: nginx/1.17.3
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-39) (GCC) 
built with OpenSSL 1.0.2k-fips  26 Jan 2017
TLS SNI support enabled
configure arguments: --add-module=modules/ngx_http_upstream_check_module --add-module=modules/ngx_http_upstream_dynamic_module --add-module=modules/ngx_http_upstream_consistent_hash_module --add-module=modules/ngx_http_upstream_keepalive_module --add-module=modules/ngx_multi_upstream_module --add-module=modules/ngx_http_upstream_vnswrr_module --add-module=modules/ngx_http_reqstat_module --add-module=/usr/src/nginx-module-vts --prefix=/data/apps/opt/tengine-2.3.2 --conf-path=/data/apps/config/nginx/nginx.conf --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_slice_module --with-pcre --with-pcre-jit --with-google_perftools_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic' --with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E' --without-http_upstream_keepalive_module
```


## 问题
nginx 编译好之后，默认的conf目录下会有如下文件
```bash
$ ls /data/apps/config/nginx/ -l
total 84
drwxr-xr-x 2 nginx nginx   39 Dec 19 14:16 conf.d
-rw-r--r-- 1 nginx nginx 1077 Sep 11  2019 fastcgi.conf
-rw-r--r-- 1 nginx nginx 1077 Sep 11  2019 fastcgi.conf.default
-rw-r--r-- 1 nginx nginx 1007 Sep 11  2019 fastcgi_params
-rw-r--r-- 1 nginx nginx 1007 Sep 11  2019 fastcgi_params.default
-rw-r--r-- 1 nginx nginx 2837 Sep 11  2019 koi-utf
-rw-r--r-- 1 nginx nginx 2223 Sep 11  2019 koi-win
-rw-r--r-- 1 nginx nginx 5231 Sep 11  2019 mime.types
-rw-r--r-- 1 nginx nginx 5231 Sep 11  2019 mime.types.default
-rw-r--r-- 1 nginx nginx 5880 Oct 31  2019 nginx.conf
-rw-r--r-- 1 nginx nginx 2656 Sep 11  2019 nginx.conf.default
-rw-r--r-- 1 nginx nginx  636 Sep 11  2019 scgi_params
-rw-r--r-- 1 nginx nginx  636 Sep 11  2019 scgi_params.default
-rw-r--r-- 1 nginx nginx  664 Sep 11  2019 uwsgi_params
-rw-r--r-- 1 nginx nginx  664 Sep 11  2019 uwsgi_params.default
-rw-r--r-- 1 nginx nginx 3610 Sep 11  2019 win-utf

```
这些文件的内容并不能确定一定是一样的，如何将其copy至目标机器上，就是一个问题。

* 将这些文件都写在 `nginx_confs` 变量中复制过去，最简单的做法，但是一般情况下变化的只有 nginx.conf 这一个文件而已,而其他的文件在copy时也会浪费时间。
* 增加了 `nginx_other_confs` 的变量，包含了一些辅助的配置文件.可以自己指定这个变量

