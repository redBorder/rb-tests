#!/bin/bash

function check_postgresql() {
  local service="postgresql"
  e_title "$service"
  local nodecount=$(rb_nodes_with_service.rb $service|wc -l)
  [ $nodecount -ge 2 ] && service_up "pgpool"
  service_up "$service"

  if [ $nodecount -ge 2 ]; then
    printf "%-90s" "Check 'rb_pcp.sh status': "
    rb_pcp.sh status|grep -q down
    print_result_opposite $? "ERROR: pgpool has members down"
  fi

  printf "%-90s" "Checking redborder database: "
  echo "select * from users; " | rb_psql redborder &>/dev/null
  print_result $? "ERROR: Cannot get postgresql users"
  printf "%-90s" "Checking druid database: "
  echo "select * from druid_rules; " | rb_psql druid &>/dev/null
  print_result $? "ERROR: Cannot get postgresql druid rules"
  printf "%-90s" "Checking opscode_chef database: "
  echo "select * from cookbooks; " | rb_psql opscode_chef &>/dev/null
  print_result $? "ERROR: Cannot get postgresql cookbooks"
}

