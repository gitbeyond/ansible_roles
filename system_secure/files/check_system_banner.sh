#!/bin/bash
ssh_status=`ps -ef|egrep "sshd"|egrep -v "grep"|wc -l`; 
if [ -s /etc/issue ] 
 then cat /etc/issue 
  redhat_count=`cat /etc/issue | egrep -i "Red Hat" | wc -l` 
  suse_count=`cat /etc/issue | egrep -i "suse" | wc -l`
  centos_count=`cat /etc/issue | egrep -i "CentOS" | wc -l`
  else 
  redhat_count=0
  suse_count=0
  centos_count=0
 fi 
if ([ $redhat_count -ge 1 ] || [ $suse_count -ge 1 ] || [ $centos_count -ge 1 ]) 
 then beforeresult=1; 
 echo "issue contain messgae.check result:false"
 exit 5
 else 
 beforeresult=0;
 echo "issue contain no messgae.check result:true"
 fi;
if [ -s /etc/issue.net ] 
 then cat /etc/issue.net 
  redhat_count=`cat /etc/issue.net | egrep -i "Red Hat" | wc -l` 
  suse_count=`cat /etc/issue.net | egrep -i "suse" | wc -l`
  centos_count=`cat /etc/issue | egrep -i "CentOS" | wc -l`
  else
  redhat_count=0
  suse_count=0
  centos_count=0
 fi 
if ([ $redhat_count -ge 1 ] || [ $suse_count -ge 1 ] || [ $centos_count -ge 1 ]) 
 then telnetresult=1 
 else telnetresult=0
 fi
if [ $ssh_status -ne 0 ]
then 
if [ -f /etc/ssh/sshd_config ] 
 then 
 ssh_bannerfile=`cat /etc/ssh/sshd_config |sed '/^\s*#/d'| egrep "Banner" | awk '{print $2}'`
if ( [ -s /etc/motd ] && [ -f $ssh_bannerfile ]); 
 then 
  echo "sshd:on,banner not null,result:true"; 
 else
  echo "sshd:on,banner null,result:false"; 
  exit 2
  fi;
  else 
  echo "sshd:on,banner null,result:false"; 
  exit 3
 fi;
else 
 echo "sshd:off,result:true"; 
 fi; 
telnet_status=`netstat -an|egrep ":23\>"|egrep -i listen|wc -l`;
if ([ $telnetresult -eq 1 ] && [ $telnet_status -eq 1 ]); 
 then 
  echo "telnet:on.banner not valid.result:false";
  exit 1
  else 
  if [ $telnetresult -eq 1 ]; 
 then 
 echo "telnet:off.banner not valid.result:true"; 
 else 
  if [ $telnet_status -eq 1 ]; 
 then 
 echo "telnet:on.banner valid.result:true"; 
 else 
 echo "telnet:off.banner valid.result:true"; 
 fi; 
 fi; 
 fi;
