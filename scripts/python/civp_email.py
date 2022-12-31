#!/usr/bin/python
# -*- coding: utf-8 -*-

from email import encoders
from email.header import Header
from email.mime.text import MIMEText
from email.utils import parseaddr, formataddr
import smtplib
import sys

from_addr = 'zabbix@mydomain.com'
password = ''
to_addr = ''
smtp_server = 'smtp.263.net'


def _format_addr(s):
    name, addr = parseaddr(s)
    return formataddr((
        Header(name, 'utf-8').encode(),
        addr.encode('utf-8') if isinstance(addr, unicode) else addr))



#msg_text="""
#%s civp log put to hdfs already succeed.
#log size is %s.
#"""
msg_text=sys.argv[1]

#msg = MIMEText('hello, send by Python...', 'plain', 'utf-8')
msg = MIMEText(msg_text, 'plain', 'utf-8')
msg['From'] = _format_addr(u'civplog_reporter <%s>' % from_addr)
msg['To'] = _format_addr(u'SA <%s>' % to_addr)
msg['subject'] = Header(u'civp log put hdfs status ','utf-8').encode()

server = smtplib.SMTP(smtp_server, 25)
#server.set_debuglevel(1)
server.login(from_addr, password)
server.sendmail(from_addr, [to_addr], msg.as_string())
server.quit()
