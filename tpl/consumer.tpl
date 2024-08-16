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

# Set variables for scripts
export VPC_ENDPOINT_DNS_NAME=${vpc_endpoint_dns_name}
export S3_BUCKET_DNS_NAME=${s3_bucket_dns_name}
export SQS_DNS_NAME=${sqs_dns_name}
export AWS_REGION=${aws_region}

# Add the VPC endpoint DNS name to /etc/profile for all users
echo "export VPC_ENDPOINT_DNS_NAME=${vpc_endpoint_dns_name}" | sudo tee -a /etc/profile
echo "export S3_BUCKET_DNS_NAME=${s3_bucket_dns_name}" | sudo tee -a /etc/profile
echo "export SQS_DNS_NAME=${sqs_dns_name}" | sudo tee -a /etc/profile
echo "export AWS_REGION=${aws_region}" | sudo tee -a /etc/profile


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
  echo "Use the following curl command to interact with the PrivateLink endpoint:"
  echo "curl -vvv http://$VPC_ENDPOINT_DNS_NAME:9090    # Jndi Exploit"
  echo "curl -o notavirus.txt http://$VPC_ENDPOINT_DNS_NAME:9090/proxy?url=https://www.eicar.org/download/eicar-com/?wpdmdl=8840&refresh=66ba2790   # Internet Access"
  echo "sudo /usr/local/bin/strutsxploit.sh   # Struts Vulnerability"
  echo ""
  echo "After sqs-sql-attack run to validate"
  echo 'mysql -u vulnuser -ppassword -e "SELECT * FROM vulnerable_db.orders;"'
  echo "Orders Table should contain"
  echo ""
} | sudo tee /usr/lib/motd.d/30-banner

# Install jq
sudo yum update -y
sudo yum install python3 python3-pip -y
sudo yum install mariadb105-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

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

cat <<'EOF' > /usr/local/bin/consumer_startup.sh
${startup_script}
EOF

cat <<'EOF' > /home/ec2-user/.env
${payload_txt}
EOF

cat <<'EOF' > /usr/local/bin/strutsxploit.sh
${strutsxploit}
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/strutsxploit.sh

cat <<'EOF' > /home/ec2-user/consumer_sqs_vuln.py
${sqs_mysql}
EOF

cat <<'EOF' > /usr/local/bin/install_guardduty_agent.sh
${guardduty_agent_script}
EOF

# Replace placeholder with actual VPC endpoint DNS name
sed -i "s/VPC_ENDPOINT_DNS_NAME/${vpc_endpoint_dns_name}/g" /usr/local/bin/strutsxploit.sh
sed -i "s/REGION/${aws_region}/g" /home/ec2-user/consumer_sqs_vuln.py
sed -i "s#SQSURL#${sqs_dns_name}#g" /home/ec2-user/consumer_sqs_vuln.py


sudo mysql -e "CREATE DATABASE vulnerable_db;"
sudo mysql -e "CREATE USER 'vulnuser'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON vulnerable_db.* TO 'vulnuser'@'localhost';"
sudo mysql -e "USE vulnerable_db; CREATE TABLE orders (id INT AUTO_INCREMENT PRIMARY KEY, user_id VARCHAR(255), product_id VARCHAR(255), quantity INT);"

# Add some test entries to the orders table
sudo mysql -e "USE vulnerable_db; INSERT INTO orders (user_id, product_id, quantity) VALUES ('user1', 'product1', 10), ('user2', 'product2', 20);"

# Add MySQL data to MOTD
mysql -u vulnuser -ppassword -e "SELECT * FROM vulnerable_db.orders;" | sudo tee -a /usr/lib/motd.d/30-banner

sudo systemctl restart mariadb

chmod +x /usr/local/bin/consumer_startup.sh
sudo /usr/local/bin/consumer_startup.sh
chmod +x /usr/local/bin/install_guardduty_agent.sh
sudo /usr/local/bin/install_guardduty_agent.sh

{
  echo "[Unit]"
  echo "Description=Vulnerable SQS Consumer Service"
  echo "After=network.target"
  echo ""
  echo "[Service]"
  echo "ExecStart=/usr/bin/python3 /home/ec2-user/consumer_sqs_vuln.py"
  echo "Restart=always"
  echo "User=ec2-user"
  echo "Group=ec2-user"
  echo "Environment=PATH=/usr/bin:/usr/local/bin"
  echo "WorkingDirectory=/home/ec2-user"
  echo ""
  echo "[Install]"
  echo "WantedBy=multi-user.target"
} | sudo tee /etc/systemd/system/vuln-sqs.service

sudo systemctl start vuln-sqs
sudo systemctl enable vuln-sqs
sudo systemctl daemon-reload

