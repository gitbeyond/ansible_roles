FROM centos:centos7
MAINTAINER wanghaifeng <haifengsss@163.com>

LABEL name="CentOS7 with nodejs-v14"

# JAVA INSTALL
COPY node /usr/local/node
COPY dumb-init /usr/bin/dumb-init
RUN  rm -rf  /etc/localtime \
     && ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && ln -sv /usr/local/node /usr/local/alinode \
     && yum -y install fontpackages-filesystem iproute net-tools\
     && groupadd -g 510 node ; useradd -g 510 -u 510 node \
     && rm -rf /var/cache/yum 

ENV PATH /usr/local/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
#ENTRYPOINT ["/usr/bin/dumb-init", "--"]
#CMD ["/usr/local/alinode/bin/npm", "--prefix=/usr/local/app", "start"]

