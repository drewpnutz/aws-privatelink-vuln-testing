#!/bin/bash
mkdir -p /home/ec2-user/.ssh
echo '${public_key}' >> /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

# Set variables for scripts
export SQS_DNS_NAME=${sqs_dns_name}
export AWS_REGION=${aws_region}

ASCII_ART='    .___                                                             
  __| _/______   ______  _  ________ ___.__.    _____________  ____  
 / __ |\_  __ \_/ __ \ \/ \/ /\____ <   |  |    \____ \_  __ \/  _ \ 
/ /_/ | |  | \/\  ___/\     / |  |_> >___  |    |  |_> >  | \(  <_> )
\____ | |__|    \___  >\/\_/  |   __// ____| /\ |   __/|__|   \____/ 
     \/             \/        |__|   \/      \/ |__|                 '

# Create the new banner content directly into the file
{
  echo "$ASCII_ART"
  echo ""
  echo "Welcome to the Producer VM."
  echo "Use the following curl command to interact with the local applications:"
  echo "curl -vvv "http://localhost:9090"  # Test flask server"
  echo "curl -Ovvv "http://localhost:9090//proxy?url=https://www.eicar.org/download/eicar-com/?wpdmdl=8840&refresh=66ba2790"   # Test internet through flask reverse proxy"
  echo "python3 sqs_sql_attack.py  # SQL SQS Attack"
} | sudo tee /usr/lib/motd.d/30-banner

sudo systemctl daemon-reload

# Add vars to /etc/profile for all users
echo "export SQS_DNS_NAME=${sqs_dns_name}" | sudo tee -a /etc/profile
echo "export AWS_REGION=${aws_region}" | sudo tee -a /etc/profile

# Install required packages
sudo yum update -y
sudo yum install -y docker git python3 python3-pip

# Install SSM Agent
sudo yum install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent
cat <<'EOF' > /opt/aws/amazon-cloudwatch-agent/bin/config.json
${cloudwatch_config}
EOF
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Install python packages
sudo pip3 install flask requests boto3 mysql-connector-python

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -aG docker ec2-user

# Clone Vulhub repository
git clone https://github.com/vulhub/vulhub.git /home/ec2-user/vulhub

# Set up Struts2 vulnerable environment (S2-061 for example)
cd /home/ec2-user/vulhub/struts2/s2-032
sudo docker-compose up -d

# Copy configuration files
cat <<'EOF' > /home/ec2-user/flask-jndi.py
${flask_script}
EOF

cat <<'EOF' > /usr/local/bin/producer_startup.sh
${startup_script}
EOF

cat <<'EOF' > /usr/local/bin/random_sqs_messages.sh
${random_sqs_messages}
EOF

cat <<'EOF' > /home/ec2-user/sqs_sql_attack.py
${sqs_sql_attack}
EOF

cat <<'EOF' > /usr/local/bin/install_guardduty_agent.sh
${guardduty_agent_script}
EOF

# Update jndi-flask service
{
  echo "[Unit]"
  echo "Description=JNDI Flask Application"
  echo ""
  echo "[Service]"
  echo "ExecStart=/usr/bin/python3 /home/ec2-user/flask-jndi.py"
  echo "Restart=always"
  echo ""
  echo "User=ec2-user"
  echo ""
  echo "[Install]"
  echo "WantedBy=multi-user.target"
} | sudo tee /etc/systemd/system/flask-jndi.service

# Start and enable services
sudo systemctl start flask-jndi
sudo systemctl enable flask-jndi

# Replace placeholder with var lookups
sudo sed -i "s/REGION/${aws_region}/g" /home/ec2-user/sqs_sql_attack.py
sudo sed -i "s|SQLURL|${sqs_dns_name}|g" /home/ec2-user/sqs_sql_attack.py
sudo sed -i "s/REGION/${aws_region}/g" /usr/local/bin/random_sqs_messages.sh
sudo sed -i "s|SQLURL|${sqs_dns_name}|g" /usr/local/bin/random_sqs_messages.sh

sudo chmod +x /usr/local/bin/producer_startup.sh
sudo /usr/local/bin/producer_startup.sh
chmod +x /usr/local/bin/install_guardduty_agent.sh
sudo /usr/local/bin/install_guardduty_agent.sh
sudo chmod +x /usr/local/bin/random_sqs_messages.sh
sudo /usr/local/bin/random_sqs_messages.sh
