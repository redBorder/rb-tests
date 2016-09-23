#!/bin/bash

function check_druid_base(){
  mode="$1"
  shift
  e_title "druid_$mode"

  service_up "druid_$mode"

  if [ $? -eq 0 ]; then
    local actives=$(rb_get_druid_${mode}s.rb)

    check_output_command "rb_get_druid_${mode}s.rb"
    if [ "x$actives" != "x" ]; then
      for n in $actives; do
        check_output_command "curl -m 10 -s ${n}/status | grep kafka|grep s3|grep totalMemory"
        for i in `seq 1 $#`; do
          eval cmd=\$$i
          check_output_command "curl -m 10 -s ${n}/${cmd}"
        done
      done
    fi
  fi
}

function check_druid_coordinator(){
  check_druid_base "coordinator" "druid/coordinator/v1/loadqueue?full|grep segmentsToLoad"
}

function check_druid_overlord(){
  check_druid_base "overlord"
  local actives=$(rb_get_druid_overlords.rb)
  #for n in $actives; do
  #  capacity=$(rb_manager_ssh.sh $n rb_get_tasks.sh -)
  #done
}

function check_druid_broker(){
  check_druid_base "broker" "druid/v2/datasources | grep rb_" "druid/broker/v1/loadstatus |grep inventoryInitialized|grep true"
}

function check_druid_middleManager(){
  check_druid_base "middleManager" "druid/worker/v1/enabled|grep :8091|grep true"
}

function check_druid_realtime(){
  check_druid_base "realtime"
}

function check_druid_historical(){
  check_druid_base "historical" "druid/historical/v1/loadstatus|grep cacheInitialized|grep true"
}

