#!/bin/bash
uname -a 
if [ -f /etc/SuSE-release ]; 
  then 
   cat /etc/SuSE-release; 
   uname -a; 
  else 
   if [ -f /etc/redhat-release ]; 
   then 
  cat /etc/redhat-release; 
   uname -a; 
  fi; 
  fi; 
