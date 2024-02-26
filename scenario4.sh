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
create_namespace "nsH4"
create_namespace "nsH3"
create_namespace "nsH2"
create_namespace "nsH1"
create_namespace "nsS1"

sudo ip netns exec nsS1 ip link add veth1 type veth peer name veth3
sudo ip netns exec nsS1 ip link set veth3 netns nsH1
sudo ip netns exec nsS1 ip link add veth2 type veth peer name veth4
sudo ip netns exec nsS1 ip link set veth4 netns nsH2
sudo ip netns exec nsS1 ip link add veth7 type veth peer name veth9
sudo ip netns exec nsS1 ip link set veth9 netns nsH3
sudo ip netns exec nsS1 ip link add veth8 type veth peer name veth10
sudo ip netns exec nsS1 ip link set veth10 netns nsH4

sudo ip netns exec nsS1 ip link add name S1 type bridge

sudo ip netns exec nsS1 ip link set dev veth1 up
sudo ip netns exec nsS1 ip link set dev veth2 up
sudo ip netns exec nsS1 ip link set dev veth7 up
sudo ip netns exec nsS1 ip link set dev veth8 up
sudo ip netns exec nsS1 ip link set S1 up

sudo ip netns exec nsH1 ip addr add 192.168.100.1/24 dev veth3
sudo ip netns exec nsH1 ip link set dev veth3 up
sudo ip netns exec nsH2 ip addr add 192.168.100.2/24 dev veth4
sudo ip netns exec nsH2 ip link set dev veth4 up
sudo ip netns exec nsH3 ip addr add 192.168.100.4/24 dev veth9
sudo ip netns exec nsH3 ip link set dev veth9 up
sudo ip netns exec nsH4 ip addr add 192.168.100.5/24 dev veth10
sudo ip netns exec nsH4 ip link set dev veth10 up

sudo ip netns exec nsS1 ip link set dev veth1 master S1
sudo ip netns exec nsS1 ip link set dev veth2 master S1
sudo ip netns exec nsS1 ip link set dev veth7 master S1
sudo ip netns exec nsS1 ip link set dev veth8 master S1

# Create new veth link in the default namespace and reassign one endpoint to S1 namespace
sudo ip link add veth6 type veth peer name veth5
sudo ip link set veth5 netns nsS1

# Activate and assign veth5 to the switch
sudo ip netns exec nsS1 ip link set dev veth5 master S1
sudo ip netns exec nsS1 ip link set dev veth5 up

# Assign IP address and activate veth6
sudo ip addr add 192.168.100.3/24 dev veth6
sudo ip link set dev veth6 up

sudo sysctl net.ipv4.ip_forward=1

sudo iptables -P FORWARD DROP
sudo iptables -F FORWARD
sudo iptables -t nat -F

sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o enp0s3 -j MASQUERADE

sudo iptables -A FORWARD -i enp0s3 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o enp0s3 -j ACCEPT

sudo ip netns exec nsH1 ip route add default via 192.168.100.3
sudo ip netns exec nsH2 ip route add default via 192.168.100.3
sudo ip netns exec nsH3 ip route add default via 192.168.100.3
sudo ip netns exec nsH4 ip route add default via 192.168.100.3

# sudo ip netns exec nsH1 ping -c1 127.0.0.1
# List NetworkNamespaces
ip netns list
