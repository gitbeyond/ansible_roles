# -*- coding: utf-8 -*-
# editor: wanghaifeng@idstaff.com
# create date: 2021/02/01
# 脚本的作用是根据配置文件，生成可用的ip池，存入 redis 中

# pip install redis
import redis
import json
import os
import sys
import logging
from IPy import IP
import pysnooper


redis_server = '127.0.0.1'
redis_port = 6379
redis_db = 0
redis_password = None

libvirt_static_network_conf_file = 'libvirt_static_network.json'


network_free_ip_pool_key_suffix = '_free_pool'
network_gateway_key_suffix = '_gateway'
network_nameservers_key_suffix = '_nameservers'
network_exclude_ip_key_suffix = '_exclude_ip'
network_allocate_ip_pool_key_suffix = '_allocation'


logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s')

def read_conf(conf_file):
    if not conf_file:
        logging.debug("please provide the conf_file arg.")
        return False

    if os.path.isfile(conf_file):
        pass
    else:
        logging.error("the %s isn't exist." % conf_file )
        return False

    with open(conf_file, 'r') as conf:
        conf_json = conf.read()

    conf_dict = json.loads(conf_json)
    # 如果某个 network 没有定义全信息，那么把全局的变量写入到这个 network 中
    for network in conf_dict['networks']:
        # 用网段信息生成一个 IP 实例
        ip_network = IP(network['network'])
        
        # 检查网段是不是私有网段
        if ip_network.iptype() != 'PRIVATE':
            logging.error("the %s isn't a private network." % network['network'])
            return False

        # 如果没有配置网关，默认是这个网段的第一个地址
        network.setdefault('gateway', str(ip_network[1]))
        
        # 如果没有 nameserver ,设置全局的nameserver
        network.setdefault('nameservers', conf_dict['nameservers'])

        # 如果没有 exclude_ip,那么把网关和广播地址写入,或者说有的话，也把这两个地址添加进去
        network_exclude_ip = network.get('exclude_ip')
        if network_exclude_ip:
            # 网关排除掉
            if network['gateway'] not in network_exclude_ip:
                network['exclude_ip'].append(network['gateway'])
            
            # 广播地址排除掉
            if str(ip_network.broadcast()) not in network_exclude_ip:
                network['exclude_ip'].append(str(ip_network.broadcast()))
            
            # 网段排除掉
            if str(ip_network.net()) not in network_exclude_ip:
                network['exclude_ip'].append(str(ip_network.net()))
        else:
            # 如果没有这个键，那么创建
            network['exclude_ip'] = [network['gateway'], str(ip_network.broadcast()), str(ip_network.net())]

    return conf_dict




#print(json.dumps(conf_dict))

@pysnooper.snoop()
def write_network_to_redis(network, redis_cli):
    # 一个network包括网段，掩码，和排除掉的ip

    network_str = network['network']
    exclude_ip = network['exclude_ip']
    gateway = network['gateway']
    nameservers = network['nameservers']

    # 网段中所有的ip，包括广播地址
    network_all_ip_set = set([ str(ip) for ip in IP(network_str) ])

    # 设置 redis 中，网络的 key 名称,全部以网段开头
    network_free_ip_pool_key = network_str + network_free_ip_pool_key_suffix
    network_gateway_key = network_str + network_gateway_key_suffix
    network_nameservers_key = network_str + network_nameservers_key_suffix
    network_exclude_ip_key = network_str + network_exclude_ip_key_suffix
    # 代表着更新后的 exclude_ip, 暂时不用这个 key 了
    #network_exclude_new_ip_key = network_str + '_new_exclude_ip'
    network_allocate_ip_pool_key = network_str + network_allocate_ip_pool_key_suffix

    # 配置文件中的 exclude_ip 值
    exclude_ip_set = set(exclude_ip)
    # 这个是为了存储 new_exclude_ip 与 exclude_ip 的并集
    # network_exclude_ip_union = set() 后来感觉这个没用
    #
    #  判断 network_exclude_ip_key 是否存在
    if redis_cli.exists(network_exclude_ip_key):
        # 这里感觉，即使其已经存在于 redis 之中了，那么还是应该以配置文件的为准
        # 那么可能的情况是:
        # 配置文件里，新增了
        # 配置文件里，减少了
        # 配置文件里，完全不一样了
        # 使用并集获得真正的 exclude_ip_set

        # 获取redis中已存在的 exclude_ip
        network_eclude_ip_old_set = redis_cli.smembers(network_exclude_ip_key)
        # 如果新旧不一样
        if network_eclude_ip_old_set != exclude_ip_set:
            # 将配置文件中新的 exclude_ip 存入key
            # redis_cli.sadd(network_exclude_new_ip_key, *exclude_ip_set)

            # 这个并集的值是用来获取新的可用ip池的
            # 感觉这个操作好像没用，exclude_ip 更新后，应该直接使用更新后的配置才对啊
            # network_exclude_ip_union = redis_cli.sunion(network_exclude_ip_key, network_exclude_new_ip_key)
            # 再将并集结果写入到 network_exclude_ip_key

            # 这里并不能确定，到底谁比谁多，也就不太确定该使用 sdiff("set1", "set2") 还是 sdiff("set2","set1") 了
            # 所以也就不能直接把“已经存在的 network_allocate_ip_pool_key” 直接来操作新的并集，万一新的并集，比原来还少呢？
            # 比如现在的 ip 池是
            # 
            # redis_cli.sadd(network_exclude_ip_key, *network_exclude_ip_union)
            # 删除network_exclude_new_ip_key
            pipe = redis_cli.pipeline()
            pipe.delete(network_exclude_ip_key)
            pipe.sadd(network_exclude_ip_key, *exclude_ip_set)
            pipe.execute()
            """
            # 下面这种情况，演示了当 exclude_ip 更新后，如果直接在原ip池上操作，那么将丢失 172.16.1.2 这个ip
            In [184]: network_allocate_ip_pool_key = {"172.16.1.5", "172.16.1.6", "172.16.1.7"}

            In [185]: network_exclude_ip_key = {"172.16.1.1", "172.16.1.2"}

            In [186]: network_exclude_new_ip_key = {"172.16.1.1", "172.16.1.3"}

            In [187]: network_allocate_ip_set = {"172.16.1.4"}

            # 差集，并集示例
            In [174]: conn.smembers("set1")
            Out[174]: {'172.16.1.1', '172.16.1.2'}

            In [175]: conn.smembers("set2")
            Out[175]: {'172.16.1.2', '172.16.1.3', '172.16.1.4'}

            In [176]: conn.sdiff("set1", "set2")
            Out[176]: {'172.16.1.1'}

            In [177]: conn.sdiff("set2", "set1")
            Out[177]: {'172.16.1.3', '172.16.1.4'}

            In [178]: conn.sunion("set2", "set1")
            Out[178]: {'172.16.1.1', '172.16.1.2', '172.16.1.3', '172.16.1.4'}
            
            In [179]: conn.sunion("set1","set2")
            Out[179]: {'172.16.1.1', '172.16.1.2', '172.16.1.3', '172.16.1.4'}

            In [181]: conn.sadd("set1", *(conn.sunion("set1","set2")))
            Out[181]: 2

            In [182]: conn.smembers("set1")
            Out[182]: {'172.16.1.1', '172.16.1.2', '172.16.1.3', '172.16.1.4'}

            """

    else:
        # 如果这个 network_exclude_ip_key 不存在，那么直接存入即可
        redis_cli.sadd(network_exclude_ip_key, *exclude_ip_set)
    
    # 初始化时，获取可用的ip set，即ip还没有被分配
    network_all_free_ip_set = network_all_ip_set - exclude_ip_set

    network_allocate_ip_set = set()
    # 判断network_allocate_ip_pool_key是否存在
    if redis_cli.exists(network_allocate_ip_pool_key):
        # 如果ip池已经开始工作，并把ip分配出去了，那么这个key是存在的
        # 取出其中的值
        network_allocate_ip_set = redis_cli.smembers(network_allocate_ip_pool_key)
    

    # 如果已分配ip池存在，再去除掉这个ip的值
    if network_allocate_ip_set:
        network_all_free_ip_set = network_all_free_ip_set - network_allocate_ip_set

    logging.debug("the network_all_free_ip_set is: %s" % network_all_free_ip_set)

    pipe = redis_cli.pipeline()
    # 写入ip池,是否更新，上面已经判断好了
    pipe.sadd(network_free_ip_pool_key, *network_all_free_ip_set)
    # 写入gateway
    pipe.set(network_gateway_key, gateway)
    # 写入nameserers ,由于是集合，写多次也没问题
    pipe.sadd(network_nameservers_key, *nameservers)
    pipe.execute()
    
    # 已分配的ip这里没法操作
    # pipe.sadd(network_allocate_ip_pool_key,"")
    
    # 如果这个 network_allocate_ip_pool_key 已经存在了呢？
    # 比如说，ip池建好了，然后运行了一段时间，ip 已经分出去了呢？
        # 这种情况下，直接排除这些ip

    # 如果说，ip 池已经建好了，但是又修改了 exclude_ip 的参数呢？ 
        # 直接以新的参数为准，重建ip池，重建时考虑已分配ip的列表

    # ip已经分配出去了，才发现这个ip是应该存在于 exclude_ip 列表当中的
    # 


def main():
    count = 0 
    conf_dict = read_conf(libvirt_static_network_conf_file)
    redis_cli = redis.StrictRedis(host=redis_server, port=redis_port, 
            db=redis_db, password=redis_password)
    
    for network in conf_dict['networks']:
        write_network_to_redis(network, redis_cli)
        count = count + 1
        if count == 1:
            sys.exit(0)
            


if __name__ == '__main__':
    main()