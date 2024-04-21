#!/usr/bin/env bash

# Source Common Functions
source common_functions.sh
source common_functions_network.sh

sudo ip -all netns delete

# Stop and remove all local Docker containers
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

print_message "Clear Start $counter" 0

# Run the nginxdemos/hello container attached to the default docker0 bridge
container_id=$(docker run -d --net=bridge nginxdemos/hello)

# Get the PID of the Docker container
container_pid=$(docker inspect --format '{{.State.Pid}}' $container_id)

# Find the network namespace of the Docker container
ns_pid=$(nsenter -t $container_pid -n ip -o -4 route show to default | awk '{print $NF}')

# Relaunch the container to be accessible from the VM at the host’s IP address and port 8880
docker run -d -p 8880:80 nginxdemos/hello

# Find the IP address of the Docker container
container_ip=$(nsenter -t $ns_pid -n ip -o -4 addr show scope global | awk '{print $4}' | cut -d '/' -f 1)

# Display the IP address and port of the container accessible from the VM
echo "Container IP address accessible from VM: $container_ip"
echo "Port: 80"

# Make the webserver available from the host OS
echo "You can access the webserver from your host OS at http://localhost:8880"

exit 0