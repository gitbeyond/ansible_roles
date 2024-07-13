# tomcat_install
这个 role 的作用是安装 tomcat。
要注意的是 tomcat 安装时会遇到多实例的安装方式，关于多实例的方式，一般有以下两种方式:
1. 设定不同的环境变量，即设置相同的 `CATALINA_HOME` 变量指向 tomcat 的安装目录，设置不同的 `CATALINA_BASE` 变量指向当前工作目录，其中要包含`conf, logs, temp(CATALINA_TMPDIR 使用这个变量也可以设置为别的目录), webapps, work` 等目录，然后配置不同的端口，启动即可，就好像 nginx 进程使用了不同的配置文件启动了多个 nginx 进程一样。
2. 直接复制 tomcat 整个目录，这样的话，`catalina.sh` 会自动把复制后的目录当作 `CATALINA_BASE`.这个 role 采用这种方式。

role 的操作步骤如下:
1. 创建 tomcat 用户
2. 创建 tomcat 的dir(使用 `tomcat_base_name` 来命名, 如 /data/apps/opt/tomcat, /data/apps/opt/tomcat1)
3. 解压并安装 tomcat 至 /data/apps/opt/ 目录下, 创建软链
	* 这里的问题是如果使用相同的 tgz 包，那么解压出来的目录也是一样的，这就会造成多个实例都指向同一个 tomcat, 配置就会混乱
	* 因此应该为每个实例单独使用不同的名字重新使用 tar 打包

4. 复制 tomcat 的配置文件，包括 conf 下的和 bin 下的，如果定义了相关变量的话
5. 复制 tomcat 的启动脚本，如果使用 supervisor 来管理的话,这一步理论上来讲，只在测试时有用，一般情况下，我们安装的tomcat属于基础软件，安装后，是不需要启动的，当我们部署了相关的app之后才需要启动相应的tomcat
	* 比如我们有了一个 app1 的 war 包 app1.war
        * 我们创建 /data/apps/opt/app1/{conf,logs,webapps,work}, /data/apps/var/app1, /data/apps/logs/app1
        * 然后配置变量 
        	* CATALINA_HOME=/data/apps/opt/tomcat 
		* CATALINA_BASE=/data/apps/opt/app1 
		* CATALINA_OUT=/data/apps/logs/app1.out
		* CATALINA_TMPDIR=/data/apps/var/app1
	* 在这个环境变量下启动tomcat

使用示例
```yaml
- hosts: '{{project_host}}'
  remote_user: root
  roles:
    - { role: tomcat_install, tomcat_run_user: "tomcat",
        tomcat_packet: "{{packet_base_dir}}/tomcat-8.0.50.tar.gz",
        tomcat_base_name: "mytomcat",
        tomcat_conf_file: ["{{file_base_dir}}/tomcat/server.xml", "{{file_base_dir}}/tomcat/logging.properties"],
        tomcat_script_file: ["{{file_base_dir}}/tomcat/catalina.sh"]}


- hosts: my_tomcat
  remote_user: root
  vars:
    tomcat_env_vars:
      JAVA_HOME: /data/apps/opt/java
      CATALINA_OPTS: '-Xmx2048M -Xms2048M'
  roles:
    - { role: tomcat_install, tomcat_run_user: "tomcat",
        tomcat_packet: "{{packet_base_dir}}/tomcat/apache-tomcat-8.5.63.tar.gz",
        tomcat_base_name: "tomcat"}
```

变量说明
* tomcat_conf_files: 列表，指定tomcat 需要配置的文件，使用template 模块复制到 conf 目录下
* tomcat_script_files: 列表，指定tomcat 需要配置的脚本文件，使用template 模块复制到 bin 目录下
* tomcat_boot_file: path 路径，tomcat 的 supervisor 启动配置


# rpm包的tomcat的启动方式

在`/usr/libexec/tomcat/functions`脚本中有如下函数，默认情况下就是使用`run_java`来运行的，其内就是`exec`开头的`java`命令。

另外在`run_jsvc`函数中，其在命令的开头处也有`exec`命令。
`/usr/bin/jsvc`命令在`tomcat-jsvc`包中。

```bash
run() {
    if [ "${USE_JSVC}" = "true" ] ; then
        run_jsvc $@
    else
        run_java $@
    fi
}
```

当设置了`USE_JSVC`的变量后，相关的命令为
```bash
exec /usr/bin/jsvc -nodetach -pidfile /var/run/jsvc-tomcat.pid -user tomcat -outfile /usr/share/tomcat/logs/catalina.out -errfile /usr/share/tomcat/logs/catalina.out -Djavax.sql.DataSource.Factory=org.apache.commons.dbcp.BasicDataSourceFactory -classpath .:/export/java/jdk/lib/dt.jar:/export/java/jdk/lib/tools.jar:/usr/share/tomcat/bin/bootstrap.jar:/usr/share/tomcat/bin/tomcat-juli.jar:/usr/share/java/commons-daemon.jar -Dcatalina.base=/usr/share/tomcat -Dcatalina.home=/usr/share/tomcat -Djava.endorsed.dirs= -Djava.io.tmpdir=/var/cache/tomcat/temp -Djava.util.logging.config.file=/usr/share/tomcat/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager org.apache.catalina.startup.Bootstrap start
```

实际启动后，仍然是两个进程，但是实际的工作进程是运行在前台的。

# 日志问题

参考官方日志配置, 删除 `ConsoleHandler` 貌似是一个可行的方式。有待验证

* https://tomcat.apache.org/tomcat-8.5-doc/logging.html

# reference
* https://tomcat.apache.org/tomcat-8.5-doc/config/valve.html : access log attributes
