#!/bin/bash

function check_keepalived(){
  e_title "keepalived"
  service_up "keepalived"

  echo "Checking IPs configured in keepalived"
  ip=`/opt/rb/bin/rb_manager_ssh.sh all cat /etc/keepalived/keepalived.conf | grep virtual_server | awk '{print $2}'| sort | uniq`
  if [ "x$ip" != "x" ]; then
    check_output_command "rb_manager_ssh.sh all ip a | grep $ip |grep -v 'lo:0'"
  else
    echo "No virtual IP configured"
  fi
}

