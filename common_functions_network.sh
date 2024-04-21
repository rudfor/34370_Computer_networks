#!/usr/bin/env bash

# Function to create and configure namespaces
create_namespace() {
  local namespace=$1
  local run_verbose="${2:-false}"  # Use true as default if the third argument is not provided

  sudo ip netns add $namespace
  sudo ip netns exec $namespace ip link set dev lo up
  if [ "$run_verbose" = true ]; then
    sudo ip netns exec $namespace ip addr
    sudo ip netns exec $namespace ping -c1 127.0.0.1
  fi
}

# Function to create and configure veth pairs
create_veth_pairs() {
    local namespace="$1"
    local veth1="$2"
    local veth2="$3"
 
    sudo ip netns exec nsS1 ip link add "$veth1" type veth peer name "$veth2"
    sudo ip netns exec nsS1 ip link set "$veth2" netns "$namespace"
    sudo ip netns exec nsS1 ip link set dev "$veth1" up
}

# Function to configure IP addresses and bring up veth pairs
configure_ip_and_up() {
    local namespace="$1"
    local veth="$2"
    local ip_address="$3"

    sudo ip netns exec "$namespace" ip addr add "$ip_address" dev "$veth"
    sudo ip netns exec "$namespace" ip link set dev "$veth" up
}

# Delete default rouging and replace
configure_routing_namespace_ip() {
    local namespace="$1"
    local ip_address="$2"
    local run_verbose="${3:-false}"  # Use true as default if the third argument is not provided

    # Check if a default route exists in nsH1 namespace
    if sudo ip netns exec "$namespace" ip route | grep -q default; then
        sudo ip netns exec "$namespace" ip route del default
        if [ "$run_verbose" = true ]; then
            echo "Default route deleted in "$namespace" namespace."
        fi
    else
        if [ "$run_verbose" = true ]; then
            echo "No default route found in "$namespace" namespace."
        fi
    fi
    if [ "$run_verbose" = true ]; then
        echo "sudo ip netns exec $namespace ip route add default via $ip_address"
    fi
    sudo ip netns exec "$namespace" ip route add default via "$ip_address"
}