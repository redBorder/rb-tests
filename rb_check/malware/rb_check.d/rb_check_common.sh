#!/bin/bash

# Common tests

function check_install(){
  e_title "install"
  if [ -f /opt/rb/etc/managers.list ]; then
    for n in $(cat /opt/rb/etc/managers.list); do
      for m in .install-chef-server.log  .install-ks-post.log  .install-redborder-boot.log  .install-redborder-cloud.log .install-redborder-db.log; do
        printf "%-90s" "Checking $m error on $n"
        local cmd="[ -f /root/$m ] && grep -i error /root/$m 2>/dev/null|grep -v \"To check your SSL configuration, or troubleshoot errors, you can use the\"|grep -v \"INFO: HTTP Request Returned 404 Object Not Found: error\" | grep -v \"already exists\" | grep -v task.drop.deserialization.errors | grep -v \"Will not attempt to authenticate using SASL\""
        print_result_output_opposite $(rb_manager_ssh.sh $n "$cmd")
        [ $? -ne 0 ] && plog "ERROR: Errors on the installation"
      done
    done
  fi
}

function check_hd(){
  e_title "hard disk"
  if [ -f /opt/rb/etc/managers.list ]; then
    for n in $(cat /opt/rb/etc/managers.list); do
      local max=0
      local flag=0

      while read line; do
        if [ $flag -eq 0 ]; then
          local linecount=$(echo $line |wc -w)
          if [ $linecount -eq 5 ]; then
            m=$(echo $line | awk '{print $4}')
          else
            m=$(echo $line | awk '{print $5}')
          fi
          m=$(echo $m|sed 's/%//')
          [ $max -lt $m ] && max=$m
          if [ $m -ge 90 ]; then
            flag=1
          fi
        fi
      done <<< "$(rb_manager_ssh.sh $n df -h|grep '%'|grep -v 'Use%')"
      printf "%-90s" "$n disks (${max}%)"
      print_result $flag "ERROR: Disk space problem at $n (${max}%)"
    done
  fi
}

function check_memory(){
  e_title "memory"
  if [ -f /opt/rb/etc/managers.list ]; then
    for n in $(cat /opt/rb/etc/managers.list); do
      local flag=0
      local memtot=$(rb_manager_ssh.sh $n free |grep "^Mem:"|awk '{print $2}')
      local memfree=$(rb_manager_ssh.sh $n free |grep "buffers/cache"|awk '{print $4}')
      local percent=$(( $memtot - $memfree ))
      percent=$(( 100 * $percent / $memtot ))
      printf "%-90s" "$n memory used (${percent}%) "
      if [ $percent -gt 90 ]; then
        print_result 1 "ERROR: Memory used problem at $n (${percent}%)"
      else
        print_result 0
      fi
    done
  fi
}

function check_kill(){
  e_title "killed proccess"
  if [ -f /opt/rb/etc/managers.list ]; then
    for n in $(cat /opt/rb/etc/managers.list); do
      printf "%-90s" "Check killed proccesses on $n: "
      local killed=$(rb_manager_ssh.sh $n dmesg |grep killed |grep Task|awk '{print $3}'|sed 's|/||'|sort|uniq)
      if [ "x$killed" == "x" ]; then
        print_result 0
      else
        print_result 1
        for m in $killed; do
          printf "%-90s" "  * $m"
          print_result 1 "ERROR: The service $m has been killed on $n"
        done
      fi
    done
  fi
}

function check_io(){
  e_title "I/O errors proccess"
  if [ -f /opt/rb/etc/managers.list ]; then
    for n in $(cat /opt/rb/etc/managers.list); do
      printf "%-90s" "Check I/O errors proccesses on $n: "
      local result=$(rb_manager_ssh.sh $n dmesg |grep end_request |grep I/O |grep error)
      if [ "x$result" == "x" ]; then
        print_result 0
      else
        print_result 1 "ERROR: I/O error at $n"
      fi
    done
  fi
}

function check_license(){
  e_title "license"
  if [ -f /opt/rb/etc/managers.list ]; then
    local current=$(date +%s)
    local exp=$current
    for n in $(cat /opt/rb/etc/managers.list); do
      exp=$(rb_manager_ssh.sh $n /opt/rb/bin/rb_read_license.rb | grep expire_time|awk '{print $2}')
      printf "%-90s" "$n license: $(date -d @${exp})"
      if [ $current -gt $exp ]; then
        print_result 1 "ERROR: License has been expired on $n. Expire date: $(date -d @${exp})"
      elif [ $(($current + 7*24*3600)) -gt $exp ]; then # 7 days remaining 
        print_result 1 "ERROR: The license is going to expire on $n. Expire date: $(date -d @${exp})"
      else
        print_result 0
      fi
    done
  fi
}

