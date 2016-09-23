#!/bin/bash

function check_drill() {
  e_title "drill"
  service_up "drill"
  service_up "hadoop_namenode"
  service_up "hadoop_datanode"

  printf "Generating test file"
cat > rbcheck_test.json <<- EOF
{
  "test" : "test"
}
EOF
  print_result $?

  printf "Checking if exists resultData directory in hdfs"
  hdfs dfs -test -d /user/oozie/resultData
  print_result $?

  printf "Uploading file to hdfs"
  hdfs dfs -put rbcheck_test.json /user/oozie/resultData/
  print_result $?
  rm -f rbcheck_test.json

  local node=$(rb_nodes_with_service.rb drill|tr '\n' ' ')
  if [ "x$node" != "x" ] ; then
    for n in ${node}; do
      printf "Querying in node $n\n"
      query=$(curl -X POST http://$n:8047/query.json -H 'content-type: application/json' \
                -d '{"queryType":"SQL", "query": "select * from hdfs.data.`rbcheck_test.json`"}' 2> /dev/null)
      echo $query | jq .rows[].test | grep -q test
      print_result $?
    done
  fi
  printf "Cleaning hdfs test data\n"
  hdfs dfs -rm -f /user/oozie/resultData/rbcheck_test.json
  print_result $?
}
