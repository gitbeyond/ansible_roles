#!/usr/bin/python
# -*- coding: utf-8 -*-

from email import encoders
from email.header import Header
from email.mime.text import MIMEText
from email.utils import parseaddr, formataddr
import smtplib
import sys

#project_name = '{{group_names[-1]}} {{ansible_default_ipv4.address}}'
project_name = sys.argv[1]
{%raw%}
def _format_addr(s):
    name, addr = parseaddr(s)
    return formataddr((
        Header(name, 'utf-8').encode(),
        addr.encode('utf-8') if isinstance(addr, unicode) else addr))

from_addr = 'zabbix@geotmt.com'
password = '7805020sch'
to_addr = ['wanghaifeng@geotmt.com', 'yuyongxin@geotmt.com']
smtp_server = 'smtpcom.263xmail.com'
#msg_text="""
#%s civp log put to hdfs already succeed.
#log size is %s.
#"""
msg_text=sys.argv[2]

#msg = MIMEText('hello, send by Python...', 'plain', 'utf-8')
msg = MIMEText(msg_text, 'plain', 'utf-8')
msg['From'] = _format_addr(u'%s mysql_bakcup_reporter <%s>' % (project_name, from_addr))
msg['To'] = _format_addr(u'SA <%s>' % to_addr)
msg['subject'] = Header(u'%s mysql backup status ' % project_name,'utf-8').encode()

server = smtplib.SMTP(smtp_server, 25)
#server.set_debuglevel(1)
server.login(from_addr, password)
server.sendmail(from_addr, to_addr, msg.as_string())
server.quit()
{%endraw%}
