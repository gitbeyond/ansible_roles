# desc

编写脚本，生成硬件`raid`的物理磁盘的健康数据。

# 支持的监控系统

## prom

将数据写入`node_exporrer`的`--collector.textfile.directory=""`指定的目录当中。
同时需要开启`--collector.textfile`, 这个默认就是开启的。

