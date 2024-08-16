#!/bin/bash
mkdir -p /home/ec2-user/.ssh
echo '${public_key}' >> /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

sudo rm /usr/lib/motd.d/10-uname
sudo rm /usr/lib/motd.d/20-*  # Remove any other MOTD scripts

sudo sed -i 's/#PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

sudo dnf update -y
sudo dnf install -y \
  gcc libpcap-devel pcre2-devel \
  jansson-devel libcap-ng-devel libmnl-devel \
  rust cargo libunwind-devel \
  file-devel zlib-devel lz4-devel \
  libnet-devel nss-devel libyaml-devel \
  cronie nc

source $HOME/.cargo/env

# Ensure cronie (crontab) service is enabled and started
sudo systemctl enable crond
sudo systemctl start crond

# Install LuaJIT from source
wget https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz
tar -xvzf LuaJIT-2.1.0-beta3.tar.gz
cd LuaJIT-2.1.0-beta3
make
sudo make install

# Link LuaJIT libraries and include files to standard paths
sudo ln -sf /usr/local/lib/libluajit-5.1.so.2 /usr/lib64/libluajit-5.1.so.2
sudo ln -sf /usr/local/include/luajit-2.1 /usr/include/luajit-2.1

# Update the linker runtime bindings
sudo ldconfig

# Set PKG_CONFIG_PATH for LuaJIT
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Download and extract Suricata source code
cd /home/ec2-user/
wget https://www.openinfosecfoundation.org/download/suricata-7.0.0.tar.gz
sudo tar -xvzf suricata-7.0.0.tar.gz
cd suricata-7.0.0/

# Configure Suricata with all required options
sudo ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
    --enable-nfqueue --enable-luajit --with-libluajit-includes=/usr/local/include/luajit-2.1 \
    --with-libluajit-libraries=/usr/local/lib

# Compile and install Suricata
sudo make
sudo make install-full
sudo ldconfig

# Modify eth0 to ens3 if required
sudo sed -i 's/eth0/ens3/g' /etc/systemd/system/suricata.service
sudo sed -i 's/eth0/ens3/g' /etc/suricata/suricata.yaml

sudo cat <<'EOF' > /var/lib/suricata/rules/
${custom_rules}
EOF

# Update inital rules and download threat content
sudo systemctl restart suricata
sudo systemctl enable suricata
sudo suricata-update

# Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent
sudo cat <<'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml
${cloudwatch_config}
EOF

export LOG_GROUP_NAME="${cloudwatch_log_group}"

# Use sed to replace the placeholder in cloudwatch-agent.toml with the actual log group name
sed -i "s/\${cloudwatch_log_group}/$LOG_GROUP_NAME/g" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml

# Set up a cron job to update Suricata rules daily
crontab -l > /tmp/mycron 2>/dev/null || true
echo "0 0 * * * /usr/bin/suricata-update" >> /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron

# Add a cron job to run the health check every minute
crontab -l > /tmp/mycron 2>/dev/null || true
echo "* * * * * /usr/local/bin/gwlb-health-check.sh >> /var/log/gwlb-health-check.log 2>&1" >> /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron

# Reload systemd
sudo systemctl daemon-reload

# Setup GWLB HealthCheck to respond to tcp/6969
nohup nc -l -p 6969 &
