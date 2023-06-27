FROM centos:centos7
MAINTAINER wanghaifeng <haifengsss@163.com>

LABEL name="CentOS7 with JDK8"

# JAVA INSTALL
#RUN yum -y install wget  \ 
        #&& wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo  \
COPY java8 /usr/local/java8
RUN  rm -rf  /etc/localtime \
     && ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && yum -y install fontpackages-filesystem iproute \
     && groupadd -g 510 tomcat; useradd -g 510 -u 510 tomcat \
     && rm -rf /var/cache/yum

ENV JAVA_HOME /usr/local/java8
ENV PATH /usr/local/java8/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8

