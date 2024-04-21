#!/usr/bin/env bash

# Define the root directory of the shared folders on the host
host_root="/scratch/school"

# Get list of VMs
vms=$(VBoxManage list vms)

# Extract VM names
vm_names=$(echo "$vms" | cut -d' ' -f1 | sed 's/"//g')

# Iterate over VMs
for vm_name in $vm_names; do
    echo "Shared mounts for VM: $vm_name"
    
    # Get VM information in XML format
    vm_info=$(VBoxManage showvminfo "$vm_name" --machinereadable)

    # Extract shared folder information from XML
    shared_folders=$(echo "$vm_info" | grep -oP 'SharedFolderNameMachineMapping\d+=".*?"')

    # Iterate over shared folders
    while IFS= read -r line; do
        folder_name=$(echo "$line" | cut -d'=' -f2 | cut -d'"' -f2)
        folder_host_path=$(echo "$line" | cut -d'=' -f3 | cut -d'"' -f2)
        folder_full_host_path="$host_root$folder_host_path/$folder_name"
        echo "Shared folder: $folder_name"
        echo "Full host path: $folder_full_host_path"
        echo ""
    done <<< "$shared_folders"
done
