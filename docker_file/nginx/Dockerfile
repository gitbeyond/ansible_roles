FROM centos:centos7
MAINTAINER wanghaifeng <wanghaifeng@geotmt.com>

LABEL name="CentOS7 with nginx-1.16.1"

COPY nginx-1.16.1 /data/apps/opt/nginx-1.16.1
COPY nginx /data/apps/config/nginx

RUN  rm -rf  /etc/localtime \
     && ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && yum -y install fontpackages-filesystem iproute gperftools-libs\
     && groupadd -g 510 nginx ; useradd -g 510 -u 510 -s /bin/false nginx \
     && rm -rf /var/cache/yum \
     && mkdir -p /data/apps/log/nginx /data/apps/var/nginx \
     && ln -sv /data/apps/opt/nginx-1.16.1 /data/apps/opt/nginx \
     && ln -sf /dev/stdout /data/apps/log/nginx/access.log \
     && ln -sf /dev/stderr /data/apps/log/nginx/error.log \
     && chown -R nginx.nginx /data/apps/*/nginx*


CMD ["/data/apps/opt/nginx/sbin/nginx", "-g", "daemon off;"]

ENV LANG en_US.UTF-8
ENV NGINX_VERSION 1.16.1
STOPSIGNAL SIGTERM
