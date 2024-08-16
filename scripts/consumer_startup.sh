#!/bin/bash

# Set hostname
HOSTNAME="consumer-ec2-$PUBLIC_IP"
sudo hostnamectl set-hostname $HOSTNAME
sudo hostnamectl 

# Update /etc/hosts
echo "127.0.0.1   $HOSTNAME" | sudo tee -a /etc/hosts

# Update prompt for all users
echo 'export PS1="[\u@$HOSTNAME \W]\$ "' | sudo tee -a /etc/profile /etc/bash.bashrc

# Ensure the hostname is applied immediately for the current session
export PS1="[\u@$HOSTNAME \W]\$ "
