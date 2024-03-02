# Justfile
set dotenv-load := true

BUILD_WRAP_PATH := "/workspace/build-wrapper-linux-x86"

# default - list recipes
default: run
    @echo "#########################################"
    @echo "Please Specify a task:"
    @echo " -> just <recipe>            # run recipe"
    @echo " -> just -h, --help          # Print help information"
    @echo "#########################################"

# run list
[linux]
run:
    @just --list

# run - to be defined Windows
[windows]
run:
    @echo "to be defined for WINDOWS"

###############################################################################################
# Aliases - quick shortuts
###############################################################################################
#alias playbooks:=playbook_list

docker_build target='esw_delta':
    @echo "docker build - {{target}}"


# namespace S1 bridge vlan show
bvs networkNameSpace='nsS1':
    sudo ip netns exec {{networkNameSpace}} bridge vlan show

ipr networkNameSpace='nsS1':
    sudo ip netns exec {{networkNameSpace}} ip route

ping_outside networkNameSpace='nsS1':
    sudo ip netns exec {{networkNameSpace}} ping 8.8.8.8

ping_i networkNameSpace='nsS1' target_ip='10.168.100.1':
    sudo ip netns exec {{networkNameSpace}} ping -W1 {{target_ip}}

