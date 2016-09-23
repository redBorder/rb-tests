#!/bin/bash

function check_riak(){
  e_title "s3"
  service_up "nginx"

  local databucket=$(cat /etc/druid/config.sh |grep S3_BUCKET=| tr '=' ' '|tr '"' ' '|awk '{print $2}')
  local chefbucket=$(cat /etc/erchef/app.config |grep s3_platform_bucket_name|tr '"' ' '|awk '{print $2}')

  if [ "x$databucket" == "xredborder" ]; then
    service_up "riak"
    service_up "riak-cs"
    check_command "s3cmd ls"
  else
    check_command_opposite "s3cmd ls"
  fi

  local cfg_file="/root/.s3cfg"
  [ -f /root/.s3cfg-redborder ] && cfg_file="/root/.s3cfg-redborder"
  check_command "s3cmd -c $cfg_file ls s3://$databucket"
  [ -f /root/.s3cfg-rbookshelf -a "x$databucket" == "xredborder" ] && cfg_file="/root/.s3cfg-rbookshelf"
  check_command "s3cmd -c $cfg_file ls s3://${chefbucket}/organization-00000000000000000000000000000000"
  printf "%-90s" "Check s3://${chefbucket}/organization-00000000000000000000000000000000 greater than zero"
  local booksize=$(s3cmd -c $cfg_file du s3://${chefbucket}/organization-00000000000000000000000000000000 2>/dev/null|awk '{print $1}')
  if [ "x$booksize" != "x" ]; then
    if [ $booksize -gt 0 ]; then
      print_result 0
    else
      print_result 1 "s3://${chefbucket} size is 0"
    fi
  else
    print_result 1 "s3://${chefbucket} size is unknown"
  fi
}

function check_riak_segments(){
  e_title "s3 stored segments"

  #check last segment is uploaded
  currenttime=$(date +%s)
  currenttime=$(( $currenttime - $currenttime % 60  ))
  [ "x$MODULE_MONITOR" == "x1" ] && check_output_command "s3cmd ls s3://redborder/rbdata/rb_monitor"
  [ "x$MODULE_FLOW" == "x1" ] && check_output_command "s3cmd ls s3://redborder/rbdata/rb_flow"
  [ "x$MODULE_IPS" == "x1" ] && check_output_command "s3cmd ls s3://redborder/rbdata/rb_event"
  [ "x$MODULE_SOCIAL" == "x1" ] && check_output_command "s3cmd ls s3://redborder/rbdata/rb_social"
}

