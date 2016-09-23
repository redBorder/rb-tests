#!/bin/bash

function check_rabbitmq() {
  local service="rabbitmq"
  e_title "$service"
  service_up "rabbitmq"

  if [ -f /opt/rb/etc/rabbitmq/rabbitmq-pass.conf ] ; then
    check_command "rabbitmqctl status"
    check_command "rabbitmqctl list_users"
  fi
}

function check_erchef() {
  local service="chef"
  e_title "$service"
  service_up "nginx"
  service_up "erchef"
  service_up "chef-solr"
  service_up "chef-expander"
  service_up "rabbitmq"
  service_up "postgresql"
  service_up "chef-client"

  check_command "knife node list"
  check_command "knife client list"

  if [ -f /opt/rb/etc/managers.list ]; then
    for n in $(cat /opt/rb/etc/managers.list); do
      printf "%-90s" "Checking last chef-client run on $n"
      local tmp=$(rb_manager_ssh.sh $n rb_get_last_chef_run.rb -d)
      if [ "x$tmp" != "x" ]; then
        if [ $tmp -lt 600 ]; then
          print_result 0
        else
          print_result 1 "ERROR: chef-client ran long time back on $n"
        fi
      else
        print_result 1 "ERROR: chef-client ran long time back on $n"
      fi
    done
  fi
}


