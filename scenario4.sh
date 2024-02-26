#!/usr/bin/env bash

# Set default verbosity level
verbosity=0
# Counter variable
counter=0
# Function to print messages based on verbosity level
print_message() {
    local message="$1"
    local level="$2"

    # Check if verbosity is greater than or equal to the specified level
    if [ "$verbosity" -ge "$level" ]; then
        echo "$message"
    fi
}

# Parse command-line arguments for verbosity
while getopts ":v" opt; do
    case $opt in
        v)
            verbosity=$((verbosity + 1))
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Function to increment the counter
increment_counter() {
    counter=$((counter + 1))
}

# Example messages at different verbosity levels
print_message "This is a low verbosity message" 1
print_message "This is a medium verbosity message" 2
print_message "This is a high verbosity message" 3


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
print_message "Phase $counter" 1; increment_counter

sudo ip netns exec nsS1 ip link add veth1 type veth peer name veth3
sudo ip netns exec nsS1 ip link set veth3 netns nsH1
sudo ip netns exec nsS1 ip link add veth2 type veth peer name veth4
sudo ip netns exec nsS1 ip link set veth4 netns nsH2
sudo ip netns exec nsS1 ip link add veth7 type veth peer name veth9
sudo ip netns exec nsS1 ip link set veth9 netns nsH3
sudo ip netns exec nsS1 ip link add veth8 type veth peer name veth10
sudo ip netns exec nsS1 ip link set veth10 netns nsH4

sudo ip netns exec nsS1 ip link add name S1 type bridge
print_message "Phase $counter" 1; increment_counter

sudo ip netns exec nsS1 ip link set dev veth1 up
sudo ip netns exec nsS1 ip link set dev veth2 up
sudo ip netns exec nsS1 ip link set dev veth7 up
sudo ip netns exec nsS1 ip link set dev veth8 up
sudo ip netns exec nsS1 ip link set S1 up
print_message "Phase $counter" 1; increment_counter

sudo ip netns exec nsH1 ip addr add 192.168.100.1/24 dev veth3
sudo ip netns exec nsH1 ip link set dev veth3 up
sudo ip netns exec nsH2 ip addr add 192.168.100.2/24 dev veth4
sudo ip netns exec nsH2 ip link set dev veth4 up
sudo ip netns exec nsH3 ip addr add 192.168.100.3/24 dev veth9
sudo ip netns exec nsH3 ip link set dev veth9 up
sudo ip netns exec nsH4 ip addr add 192.168.100.4/24 dev veth10
sudo ip netns exec nsH4 ip link set dev veth10 up
print_message "Phase $counter" 1; increment_counter

sudo ip netns exec nsS1 ip link set dev veth1 master S1
sudo ip netns exec nsS1 ip link set dev veth2 master S1
sudo ip netns exec nsS1 ip link set dev veth7 master S1
sudo ip netns exec nsS1 ip link set dev veth8 master S1
print_message "Phase $counter" 1; increment_counter
# Create new veth link in the default namespace and reassign one endpoint to S1 namespace
sudo ip link add veth6 type veth peer name veth5
sudo ip link set veth5 netns nsS1
#sudo ip netns exec nsS1 ip link set dev veth5 up
print_message "Phase $counter" 1; increment_counter

sudo sysctl net.ipv4.ip_forward=1
print_message "Phase $counter" 1; increment_counter

sudo iptables -P FORWARD DROP
sudo iptables -F FORWARD
sudo iptables -t nat -F

sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o enp0s3 -j MASQUERADE

sudo iptables -A FORWARD -i enp0s3 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o enp0s3 -j ACCEPT

print_message "Phase $counter" 1; increment_counter

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
print_message "Segregation $counter" 0; increment_counter
sudo ip netns exec nsS1 ip link add link veth5 name veth5.77 type vlan id 77
sudo ip netns exec nsS1 ip link add link veth5 name veth5.88 type vlan id 88

print_message "Phase $counter" 1; increment_counter
sudo ip netns exec nsS1 ip link set dev veth5.77 up
sudo ip netns exec nsS1 ip link set dev veth5.88 up

print_message "Phase $counter" 1; increment_counter
sudo ip netns exec nsS1 bridge vlan del vid 1 dev 'veth5.77'
sudo ip netns exec nsS1 bridge vlan del vid 1 dev 'veth5.88'

sudo ip netns exec nsS1 bridge vlan add vid 77 pvid untagged dev veth5.77
sudo ip netns exec nsS1 bridge vlan add vid 88 pvid untagged dev veth5.88

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
sudo ip addr add 192.168.100.3/24 dev veth6
sudo ip link set dev veth6 up

sudo iptables -A FORWARD -i veth5.77 -o veth5 -j ACCEPT
sudo iptables -A FORWARD -i veth5 -o veth5.77 -j ACCEPT

sudo iptables -A FORWARD -i veth6.77 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o veth6.77 -j ACCEPT
sudo iptables -A FORWARD -i veth6.88 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o veth6.88 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o veth6 -j ACCEPT
sudo iptables -A FORWARD -i veth6 -o enp0s3 -j ACCEPT


# sudo ip netns exec nsH1 ping -c1 127.0.0.1
# List NetworkNamespaces
ip netns list
