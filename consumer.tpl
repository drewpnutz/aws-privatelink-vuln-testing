#!/bin/bash
mkdir -p /home/ec2-user/.ssh
echo '${public_key}' >> /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

# Fetch public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Set hostname
HOSTNAME="consumer-ec2-$PUBLIC_IP"
hostnamectl set-hostname $HOSTNAME

# Update /etc/hosts
echo "127.0.0.1   $HOSTNAME" >> /etc/hosts

# Update prompt
echo 'export PS1="[\u@$HOSTNAME \W]\$ "' >> /etc/profile
