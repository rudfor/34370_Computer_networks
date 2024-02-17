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

# Create and configure nsH2
create_namespace "nsH2"
# Create and configure nsH1
create_namespace "nsH1"
# Create and configure nsS1
create_namespace "nsS1"

sudo ip netns exec nsS1 ip link add veth1 type veth peer name veth3
sudo ip netns exec nsS1 ip link set veth3 netns nsH1
sudo ip netns exec nsS1 ip link add veth2 type veth peer name veth4
sudo ip netns exec nsS1 ip link set veth4 netns nsH2

sudo ip netns exec nsS1 ip link add name S1 type bridge

sudo ip netns exec nsS1 ip link set dev veth1 up
sudo ip netns exec nsS1 ip link set dev veth2 up
sudo ip netns exec nsS1 ip link set S1 up

sudo ip netns exec nsH1 ip addr add 192.168.100.1/24 dev veth3
sudo ip netns exec nsH1 ip link set dev veth3 up
sudo ip netns exec nsH2 ip addr add 192.168.100.2/24 dev veth4
sudo ip netns exec nsH2 ip link set dev veth4 up

sudo ip netns exec nsS1 ip link set dev veth1 master S1
sudo ip netns exec nsS1 ip link set dev veth2 master S1



# sudo ip netns exec nsH1 ping -c1 127.0.0.1
# List NetworkNamespaces
ip netns list
