#!/usr/bin/env bash

# Source Common Functions
source common_functions.sh

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

sudo ip -all netns delete

# Create and configure namespaces using a foreach loop
namespaces=("nsH4" "nsH3" "nsH2" "nsH1" "nsS1")
for ns in "${namespaces[@]}"; do
    create_namespace "$ns"
done
print_message "NameSpaces Created @$counter" 1

create_veth_pairs nsH1 veth1 veth3
create_veth_pairs nsH2 veth2 veth4
create_veth_pairs nsH3 veth7 veth9
create_veth_pairs nsH4 veth8 veth10

print_message "Veth Pairs Created @$counter" 1

sudo ip netns exec nsS1 ip link add name S1 type bridge
sudo ip netns exec nsS1 ip link set S1 up
print_message "Create S1 Brige $counter" 1

configure_ip_and_up "nsH1" "veth3" "192.168.100.1/24"
configure_ip_and_up "nsH2" "veth4" "192.168.100.2/24"
configure_ip_and_up "nsH3" "veth9" "192.168.100.3/24"
configure_ip_and_up "nsH4" "veth10" "192.168.100.4/24"

print_message "Configure nsHX ip $counter" 0

sudo ip netns exec nsS1 ip link set dev veth1 master S1
sudo ip netns exec nsS1 ip link set dev veth2 master S1
sudo ip netns exec nsS1 ip link set dev veth7 master S1
sudo ip netns exec nsS1 ip link set dev veth8 master S1

print_message "Assign veth to nsS1 Switch $counter" 1

# Create new veth link in the default namespace and reassign one endpoint to S1 namespace
sudo ip link add veth6 type veth peer name veth5
sudo ip link set veth5 netns nsS1

sudo ip netns exec nsS1 ip link set S1 type bridge vlan_filtering 1

sudo ip netns exec nsS1 ip link add link veth5 name veth5.77 type vlan id 77
sudo ip netns exec nsS1 ip link add link veth5 name veth5.88 type vlan id 88

print_message "Created veth5 subnet $counter" 0
sudo ip netns exec nsS1 ip link set dev veth5.77 master S1
sudo ip netns exec nsS1 ip link set dev veth5.88 master S1

sudo ip netns exec nsS1 ip link set dev veth5 up
sudo ip netns exec nsS1 ip link set dev veth5.77 up
sudo ip netns exec nsS1 ip link set dev veth5.88 up

sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth1
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth2
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth7
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth8
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.77
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.88
print_message "Bridge $counter" 0; increment_counter

sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth1
sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth2
sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth5.77

print_message "Phase $counter" 1; increment_counter
sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth7
sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth8
sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth5.88

print_message "vlan5 Setup with subnet 77 and 88 $counter" 0

sudo ip link set veth6 down
sudo ip link add link veth6 name veth6.77 type vlan id 77
sudo ip link add link veth6 name veth6.88 type vlan id 88

sudo ip addr add 192.168.100.177/24 dev veth6.77
sudo ip addr add 192.168.100.188/24 dev veth6.88

sudo ip link set dev veth6 up
sudo ip link set dev veth6.77 up
sudo ip link set dev veth6.88 up

print_message "vlan6 Setup with subnet 77 and 88 $counter" 0

configure_routing_namespace_ip nsH1 192.168.100.177
configure_routing_namespace_ip nsH2 192.168.100.177
configure_routing_namespace_ip nsH3 192.168.100.188
configure_routing_namespace_ip nsH4 192.168.100.188

print_message "Allocated Ip routes outside $counter" 0

sudo ip route add 192.168.100.1 via 192.168.100.177
sudo ip route add 192.168.100.2 via 192.168.100.177
sudo ip route add 192.168.100.3 via 192.168.100.188
sudo ip route add 192.168.100.4 via 192.168.100.188

print_message "VLAN 5, 6 Setup $counter" 0

sudo sysctl net.ipv4.ip_forward=1
print_message "Phase $counter" 1

sudo iptables -P FORWARD DROP
sudo iptables -F FORWARD
sudo iptables -t nat -F

sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o enp0s3 -j MASQUERADE

sudo iptables -A FORWARD -i enp0s3 -o veth6.77 -j ACCEPT
sudo iptables -A FORWARD -i veth6.77 -o enp0s3 -j ACCEPT

sudo iptables -A FORWARD -i enp0s3 -o veth6.88 -j ACCEPT
sudo iptables -A FORWARD -i veth6.88 -o enp0s3 -j ACCEPT

sudo iptables -A FORWARD -i enp0s3 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o enp0s3 -j ACCEPT


if [ true ] ; then
    print_message "Conditional $counter" 0
fi

exit 1
#sudo ip netns exec nsS1 ip link set dev veth5 up
# sudo ip link set veth5 netns nsS1

print_message "Phase $counter" 1

sudo sysctl net.ipv4.ip_forward=1
print_message "Phase $counter" 1

sudo iptables -P FORWARD DROP
sudo iptables -F FORWARD
sudo iptables -t nat -F

sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o enp0s3 -j MASQUERADE

sudo iptables -A FORWARD -i enp0s3 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o enp0s3 -j ACCEPT

print_message "Phase $counter" 1

print_message "Routing $counter" 0; increment_counter
sudo ip netns exec nsH1 ip route add default via 192.168.100.8
sudo ip netns exec nsH2 ip route add default via 192.168.100.8
sudo ip netns exec nsH3 ip route add default via 192.168.100.9
sudo ip netns exec nsH4 ip route add default via 192.168.100.9

sudo ip netns exec nsS1 ip link set S1 type bridge vlan_filtering 1
print_message "Phase $counter" 1; increment_counter

sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth1
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth2
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth7
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth8
print_message "Bridge $counter" 0; increment_counter
sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth1
sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth2
print_message "Phase $counter" 1; increment_counter
sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth7
sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth8


print_message "NameSpace $counter" 1; increment_counter
# Check if the namespace exists
if sudo ip netns list | grep -q "nsS1"; then
    print_message "Segregation $counter" 0; increment_counter
    sudo ip netns exec nsS1 ip link add link veth5 name veth5.77 type vlan id 77 2> NSerror.log
    sudo ip netns exec nsS1 ip link add link veth5 name veth5.88 type vlan id 88 2>> NSerror.log
    sudo ip netns exec nsS1 bridge vlan del vid 1 dev 'veth5.77' 2>> NSerror.log
    sudo ip netns exec nsS1 bridge vlan del vid 1 dev 'veth5.88' 2>> NSerror.log
    sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth5.77 2>> NSerror.log
    sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth5.88 2>> NSerror.log
else
    echo "Namespace nsS1 does not exist."
fi


print_message "5.XX up $counter" 1; increment_counter
sudo ip netns exec nsS1 ip link set dev veth5.77 up
sudo ip netns exec nsS1 ip link set dev veth5.88 up


print_message "Phase $counter" 1; increment_counter
# Remove the incorrect VLAN configuration for veth5.77 and veth5.88
# Remove VLAN interfaces from the bridge without specifying the VLAN ID
# sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.77
# sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.88
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.77
sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.88

# Add the correct VLAN configuration for veth5.77 and veth5.88
sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth5.77
sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth5.88

print_message "Phase $counter" 1; increment_counter
# Add VLAN interfaces back with the correct VLAN configuration
#sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth5.77
#sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth5.88

# print_message "Phase $counter" 1; increment_counter
# sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.77
# sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.88
print_message "Phase $counter" 1; increment_counter
# sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.77
# sudo ip netns exec nsS1 bridge vlan del vid 1 dev veth5.88

sudo ip netns exec nsS1 ip link set dev veth5.77 up
sudo ip netns exec nsS1 ip link set dev veth5.88 up

print_message "Phase $i" 1; increment_counter
# Activate and assign veth5 to the switch
sudo ip netns exec nsS1 ip link set dev veth5 master S1
sudo ip netns exec nsS1 ip link set dev veth5.77 master S1
sudo ip netns exec nsS1 ip link set dev veth5.88 master S1
sudo ip netns exec nsS1 ip link set dev veth5 up

sudo ip link add link veth6 name veth6.77 type vlan id 77
sudo ip link add link veth6 name veth6.88 type vlan id 88
sudo ip link set dev veth6.77 up
sudo ip link set dev veth6.88 up

# Assign IP address and activate veth6
sudo ip addr add 192.168.100.8/24 dev veth6.77
sudo ip addr add 192.168.100.9/24 dev veth6.88
sudo ip addr add 192.168.100.10/24 dev veth6
sudo ip link set dev veth6 up

sudo iptables -A FORWARD -i veth5.77 -o veth5 -j ACCEPT
sudo iptables -A FORWARD -i veth5 -o veth5.77 -j ACCEPT
sudo iptables -A FORWARD -i veth5.88 -o veth5 -j ACCEPT
sudo iptables -A FORWARD -i veth5 -o veth5.88 -j ACCEPT

sudo iptables -A FORWARD -i veth6.77 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o veth6.77 -j ACCEPT
sudo iptables -A FORWARD -i veth6.88 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o veth6.88 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o enp0s3 -j ACCEPT


# sudo ip netns exec nsH1 ping -c1 127.0.0.1
# List NetworkNamespaces
ip netns list
