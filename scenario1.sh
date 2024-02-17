#!/usr/bin/env bash

# Function to create and configure namespaces
create_namespace() {
  local namespace=$1
  sudo ip netns add $namespace
  sudo ip netns exec $namespace ip link set dev lo up
  sudo ip netns exec $namespace ip addr
  sudo ip netns exec $namespace ping -c1 127.0.0.1
}


sudo ip -all netns delete

# Create and configure nsH1
create_namespace "nsH1"

# Create and configure nsH2
create_namespace "nsH2"

sudo ip netns exec nsH1 ip link add veth1 type veth peer name veth2
sudo ip netns exec nsH1 ip link set dev veth2 netns nsH2

sudo ip netns exec nsH1 ip addr add 192.168.100.1/24 dev veth1
sudo ip netns exec nsH1 ip link set dev veth1 up
sudo ip netns exec nsH2 ip addr add 192.168.100.2/24 dev veth2
sudo ip netns exec nsH2 ip link set dev veth2 up


# ip netns
# # Add namespace H1
# sudo ip netns add nsH1
# # Activate namespace H1 loopback interface
# sudo ip netns exec nsH1 ip link set dev lo up
# # Show status of connections
# sudo ip netns exec nsH1 ip addr
# # Show status
# sudo ip netns exec nsH1 ping -c1 127.0.0.1
# List NetworkNamespaces
ip netns list
