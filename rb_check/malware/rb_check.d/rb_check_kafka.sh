#!/bin/bash

function check_kafka(){
  e_title "kafka"
  service_up "zookeeper"
  service_up "kafka"

  check_output_command "timeout 10s rb_get_brokers.rb |grep 9092|grep yes"
  [ "x$MODULE_MONITOR" == "x1" ] && check_output_command "timeout 10s rb_get_topics.rb -t rb_monitor | grep rb_monitor"
  [ "x$MODULE_FLOW" == "x1" ] && check_output_command "timeout 10s rb_get_topics.rb -t rb_flow | grep rb_flow"
  [ "x$MODULE_IPS" == "x1" ] && check_output_command "timeout 10s rb_get_topics.rb -t rb_event | grep rb_event"
  [ "x$MODULE_LOCATION" == "x1" ] && check_output_command "timeout 10s rb_get_topics.rb -t rb_loc |grep rb_loc"
  [ "x$MODULE_SOCIAL" == "x1" ] && check_output_command "timeout 10s rb_get_topics.rb -t rb_social |grep rb_social"
}

function check_topic(){
  printf "Check messages into %-69s " "$1"
  local topic=$1
  local out=$(rb_manager_ssh.sh "$n" timeout 60 /opt/rb/bin/rb_consumer.sh -t $1 -c 1 2>&1|tail -n 1|grep 'Consumed\|Processed'|awk '{print $2}')
  if [ "x$out" == "x0" -o "x$out" == "x" ]; then
    print_result 1 "ERROR: Kafka is not receiving messages at the topic $topic"
  else
    print_result 0
  fi
}

function check_kafka_topics(){
  e_title "kafka messages"
  service_up "kafka"

  [ "x$MODULE_MONITOR" == "x1" ] && check_topic "rb_monitor"
  [ "x$MODULE_FLOW" == "x1" ] && check_topic "rb_flow"
  [ "x$MODULE_IPS" == "x1" ] && check_topic "rb_event"
  [ "x$MODULE_LOCATION" == "x1" ] && check_topic "rb_loc"
  [ "x$MODULE_SOCIAL" == "x1" ] && check_topic "rb_social"
}

