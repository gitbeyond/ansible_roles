#!/usr/bin/python
"""{'zk_followers': 0, 
'zk_outstanding_requests': 0, 
'zk_approximate_data_size': 890971, 
'zk_packets_sent': 5818488, 
'zk_pending_syncs': 0, 
'zk_avg_latency': 0, 
'zk_version': '3.4.6-1569965, built on 02/20/2014 09:09 GMT', 
'zk_watch_count': 1364, 
'zk_packets_received': 5797681, 
'zk_open_file_descriptor_count': 46, 
'zk_server_ruok': 'imok', 
'zk_server_state': 'follower', 
'zk_synced_followers': 0, 
'zk_max_latency': 400, 
'zk_num_alive_connections': 18, 
'zk_min_latency': 0, 
'zk_ephemerals_count': 1112, 
'zk_znode_count': 2207, 
'zk_max_file_descriptor_count': 4096} 
31022
"""

import sys
import socket
import re
import subprocess
from StringIO import StringIO
import os
 
 
#zabbix_sender = '/usr/bin/zabbix_sender'
zabbix_sender = '{{zabbix_sender}}'
zabbix_conf = '{{zabbix_conf}}'
send_to_zabbix = 1


# get zookeeper server status
class ZooKeeperServer(object):
 
    def __init__(self, host='localhost', port='2181', timeout=1):
        self._address = (host, int(port))
        self._timeout = timeout
        self._result = {}

    def _create_socket(self):
        return socket.socket()

    def _send_cmd(self, cmd):
        """ Send a 4letter word command to the server """
        s = self._create_socket()
        s.settimeout(self._timeout)
 
        s.connect(self._address)
        s.send(cmd)
 
        data = s.recv(2048)
        s.close()
 
        return data
 
    def get_stats(self):
        """ Get ZooKeeper server stats as a map """
        """zk_version      3.4.6-1569965, built on 02/20/2014 09:09 GMT
            zk_avg_latency  0
            zk_max_latency  94
            zk_min_latency  0
            zk_packets_received     1267904
            zk_packets_sent 1317835
            zk_num_alive_connections        12
            zk_outstanding_requests 0
            zk_server_state follower
            zk_znode_count  1684
            zk_watch_count  2757
            zk_ephemerals_count     899
            zk_approximate_data_size        728074
            zk_open_file_descriptor_count   41
            zk_max_file_descriptor_count    4096
        """
        data_mntr = self._send_cmd('mntr')
        data_ruok = self._send_cmd('ruok')
        if data_mntr:
            result_mntr = self._parse(data_mntr)
        if data_ruok:
            # {'zk_server_ruok': 'imok'}
            result_ruok = self._parse_ruok(data_ruok)
 
        self._result = dict(result_mntr.items() + result_ruok.items())
         
        if not self._result.has_key('zk_followers') and not self._result.has_key('zk_synced_followers') and not self._result.has_key('zk_pending_syncs'):
           # #### the tree metrics only exposed on leader role zookeeper server, we just set the followers' to 0
           leader_only = {'zk_followers':0,'zk_synced_followers':0,'zk_pending_syncs':0}    
           self._result = dict(result_mntr.items() + result_ruok.items() + leader_only.items())
 
        return self._result  

    def _parse(self, data):
        """
        :param data: zk_outstanding_requests 0 zk_approximate_data_size        653931
        :return: {'zk_outstanding_requests': '0', 'zk_approximate_data_size': '653931',}
        """
        """ Parse the output from the 'mntr' 4letter word command """
        h = StringIO(data)
        result = {}
        for line in h.readlines():
            try:
                key, value = self._parse_line(line)
                result[key] = value
            except ValueError:
                pass # ignore broken lines
 
        return result
 
    def _parse_ruok(self, data):
        """
        :param data: imok
        :return: {'zk_server_ruok': 'imok'}
        """
        """ Parse the output from the 'ruok' 4letter word command """
        
        h = StringIO(data)
        result = {}
        
        ruok = h.readline()
        if ruok:
           result['zk_server_ruok'] = ruok
  
        return result
 
    def _parse_line(self, line):
        # zk_watch_count  1482
        try:
            # zk_max_file_descriptor_count 65535
            key, value = map(str.strip, line.split('\t'))
        except ValueError:
            raise ValueError('Found invalid line: %s' % line)
 
        if not key:
            raise ValueError('The key is mandatory and should not be empty')
 
        try:
            value = int(value)
        except (TypeError, ValueError):
            pass
 
        return key, value

    def get_pid(self):
        # ps -ef|grep java|grep zookeeper|awk '{print $2}'
        pidarg = '''ps -ef|grep java|grep zookeeper|grep -v grep|awk '{print $2}' '''   # 31022
        pidout = subprocess.Popen(pidarg, shell=True, stdout=subprocess.PIPE)
        pid = pidout.stdout.readline().strip('\n')
        return pid

    def send_to_zabbix(self, metric):
        # key = zookeeper.status[zk_max_file_descriptor_count]
        key = "zookeeper.status[" + metric + "]"
        if send_to_zabbix > 0:
            # print key + ":" + str(self._result[metric])
            try:
                subprocess.call([zabbix_sender, "-c", zabbix_conf, "-k", key, "-o", str(self._result[metric])], stdout=FNULL, stderr=FNULL, shell=False)
                #print "send zabbix success"
            except OSError, detail:
                print "Something went wrong while exectuting zabbix_sender : ", detail
        else:
            print "Simulation: the following command would be execucted :\n", zabbix_sender, "-c", zabbix_conf, "-k", key, "-o", self._result[metric], "\n"


def usage():
        """Display program usage"""
 
        print "\nUsage : ", sys.argv[0], " alive|all"
        print "Modes : \n\talive : Return pid of running zookeeper\n\tall : Send zookeeper stats as well"
        sys.exit(1)

        
accepted_modes = ['alive', 'all']
if len(sys.argv) == 2 and sys.argv[1] in accepted_modes:
        mode = sys.argv[1]
else:
        usage()

zk = ZooKeeperServer()
#  print zk.get_stats()
pid = zk.get_pid()
 
if pid != "" and mode == 'all':
    zk.get_stats()
    print zk._result
    FNULL = open(os.devnull, 'w')
    for key in zk._result:
       zk.send_to_zabbix(key)
    FNULL.close()
    print pid
elif pid != "" and mode == "alive":
    print pid
else:
    print 0
