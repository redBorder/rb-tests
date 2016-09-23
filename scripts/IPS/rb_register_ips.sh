 #!/bin/bash -e

sysconf_folder="/home/rb-tests/rb-tests/scripts/IPS/rb_sysconf_register"
sensorIP=$1

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $sysconf_folder/* root@$sensorIP:/opt/rb/bin/
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$sensorIP 'rb_sysconf'
