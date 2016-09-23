#!/bin/bash

NumberVirtualMachine=$1

if [ "x$NumberVirtualMachine" != "x" ] ; then
    check_vm=$(virsh list | grep "REDBORDER-MASTER-$NumberVirtualMachine"| grep ejecutando)
    if [ "x$check_vm" != "x" ] ; then 
       virsh destroy REDBORDER-MASTER-$NumberVirtualMachine
    else
       echo "REDBORDER-MASTER-$NumberVirtualMachine already down"
    fi
else
    echo "Usage $(basename $0) <NUMBER_VIRTUAL_MACHINE>"
fi
