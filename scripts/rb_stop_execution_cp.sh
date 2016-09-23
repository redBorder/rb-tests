#!/bin/bash

check_vm=$(virsh list | grep "REDBORDER-CLIENT-PROXY"| grep ejecutando)
if [ "x$check_vm" != "x" ] ; then 
    virsh destroy REDBORDER-CLIENT-PROXY
else
    echo "REDBORDER-MANAGER-$NumberVirtualMachine already down"
fi
