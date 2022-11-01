FROM centos:centos7
MAINTAINER wanghaifeng <haifengsss@163.com>

LABEL name="CentOS7 with JDK8 and tomcat8"

# JAVA INSTALL
COPY java8 /usr/local/java8
COPY tomcat8 /usr/local/tomcat8
COPY jmx_prometheus_javaagent.jar /opt/jmx_prometheus_javaagent.jar
COPY sw-agent /opt/sw-agent
RUN  rm -rf  /etc/localtime \
     && ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && yum -y install fontpackages-filesystem iproute net-tools curl telnet epel-release \
     && yum -y install jq \
     && groupadd -g 510 tomcat ; useradd -g 510 -u 510 tomcat \
     && mkdir -p /var/log/tomcat /data/apps/data \
     && chown -R 510:510 /var/log/tomcat /usr/local/tomcat8 /opt/sw-agent /data/apps/data /opt/jmx_prometheus_javaagent.jar \
     && rm -rf /var/cache/yum

#     && ln -s /dev/stdout /var/log/tomcat/tomcat_access.log \
#     && ln -s /dev/stderr /var/log/tomcat/tomcat_error.log 

ENV JAVA_HOME /usr/local/java8
ENV PATH /usr/local/tomcat8/bin:/usr/local/java8/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
#ENV CATALINA_OUT /var/log/tomcat/tomcat_error.log
ENTRYPOINT ["/usr/local/tomcat8/bin/catalina.sh", "run"]
