#!/bin/bash

function check_zookeeper(){
  e_title "zookeeper"
  service_up "zookeeper"
  check_command "echo 'ls /' | rb_zkcli"
}
