#!/bin/bash

function check_nginx(){
  e_title "nginx"
  service_up "nginx"

  local node=$(rb_nodes_with_service.rb nginx|tr '\n' ' ')
  if [ "x$node" != "x" ] ; then
    for n in ${node}; do
      echo "Checking functionality of nginx at $n"
      check_command "rb_manager_ssh.sh $n \"curl http://erchef.$DOMAIN/nginx_stub_status\""
      check_command "rb_manager_ssh.sh $n \"curl -k https://erchef.$DOMAIN/nginx_status\""
    done
  fi
}

