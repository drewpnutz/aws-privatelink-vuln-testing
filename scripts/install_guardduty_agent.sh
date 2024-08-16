#!/bin/bash
# Install the GuardDuty agent
aws s3 cp s3://593207742271-us-east-1-guardduty-agent-rpm-artifacts/1.2.0/x86_64/amazon-guardduty-agent-1.2.0.x86_64.rpm ./amazon-guardduty-agent-1.2.0.x86_64.rpm

sudo rpm -ivh amazon-guardduty-agent-1.2.0.x86_64.rpm

sudo systemctl enable amazon-guardduty-agent
sudo systemctl start amazon-guardduty-agent

