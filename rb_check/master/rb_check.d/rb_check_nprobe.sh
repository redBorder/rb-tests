#!/bin/bash

function check_nprobe(){
  e_title "nprobe (netflow)"
  service_up "zookeeper"
  service_up "nprobe"

  if [ -f /opt/rb/etc/nprobe.list -a -f /etc/nprobe/config.json ]; then
    local nprobeline=$(wc -l /etc/nprobe/config.json|awk '{print $1}')
    if [ $nprobeline -gt 4 ]; then
      for n in $(cat /opt/rb/etc/nprobe.list); do
        printf "%-90s" "Check $n is receiving netflow "
        local out=$(rb_manager_ssh.sh $n 'timeout 10 tcpdump -ni bond0 port 2055 -c 1 2>&1' |grep "packets captured"|awk '{print $1}')
        if [ $out -gt 0 ]; then
          print_result 0
        else
          print_result 1 "ERROR: $n is not receiving netflow"
        fi
      done
    fi
  fi
}
