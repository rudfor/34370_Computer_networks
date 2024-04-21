#!/usr/bin/env bash

#!/bin/bash

setup() {
    # Install bridge-utils if not installed
    if ! command -v brctl &> /dev/null; then
        echo "Installing bridge-utils..."
        sudo apt-get install -y bridge-utils
    else
        echo "bridge-utils is already installed."
    fi

    # Copy Manifests.zip to Downloads if not already copied
    if [ ! -f /home/user/Downloads/Manifests.zip ]; then
        echo "Copying Manifests.zip to Downloads..."
        cp Manifests.zip /home/user/Downloads/
    else
        echo "Manifests.zip already exists in Downloads."
    fi

    # Unzip Manifests.zip to /home/user/Manifests if not already unzipped
    if [ ! -d /home/user/Manifests ]; then
        echo "Unzipping Manifests.zip..."
        unzip -d /home/user/Manifests /home/user/Downloads/Manifests.zip
    else
        echo "Manifests are already unzipped."
    fi

    # Allow forwarding
    sudo iptables -P FORWARD ACCEPT

    # Start minikube
    sudo minikube start --driver=none

    # Link Docker netns to /var/run/netns
    sudo rm -rf /var/run/netns
    sudo ln -s /var/run/docker/netns /var/run/netns
}

disable() {
    # Stop minikube
    sudo minikube stop

    # Remove bridge-utils if installed
    if command -v brctl &> /dev/null; then
        echo "Removing bridge-utils..."
        sudo apt-get remove -y bridge-utils
    else
        echo "bridge-utils is not installed."
    fi

    # Remove copied Manifests and zip if they exist
    if [ -f /home/user/Downloads/Manifests.zip ]; then
        echo "Removing Manifests.zip from Downloads..."
        rm -f /home/user/Downloads/Manifests.zip
    else
        echo "Manifests.zip does not exist in Downloads."
    fi

    if [ -d /home/user/Manifests ]; then
        echo "Removing Manifests directory..."
        rm -rf /home/user/Manifests
    else
        echo "Manifests directory does not exist."
    fi

    # Deny forwarding
    sudo iptables -P FORWARD DROP

    # Remove symbolic link if it exists
    if [ -L /var/run/netns ]; then
        echo "Removing symbolic link..."
        sudo rm -f /var/run/netns
    else
        echo "Symbolic link does not exist."
    fi
}

# Check if parameter is passed
if [ $# -eq 0 ]; then
    echo "Usage: $0 setup|disable"
    exit 1
fi

# Execute setup or disable based on parameter
case "$1" in
    setup)
        setup
        ;;
    disable)
        disable
        ;;
    *)
        echo "Invalid option. Usage: $0 setup|disable"
        exit 1
        ;;
esac
