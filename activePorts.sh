#!/usr/bin/env bash

# Get a list of all active virtual machines
active_vms=$(VBoxManage list runningvms | awk '{print $1}' | sed 's/"//g')

# Iterate over each active virtual machine
for vm_name in $active_vms; do
    echo "Port Forwarding Rules for VM: $vm_name"
    VBoxManage showvminfo "$vm_name" --machinereadable | grep Forwarding
done