#!/usr/bin/env bash

# Source Common Functions
source common_functions.sh
source common_functions_network.sh


sudo ip -all netns delete

# Check if there are any running Docker containers
if [ "$(docker ps -aq)" ]; then
    # Stop and remove all running Docker containers
    docker stop $(docker ps -q)
    docker rm $(docker ps -aq)
else
    print_message "No running Docker containers found. $counter" 1
fi

