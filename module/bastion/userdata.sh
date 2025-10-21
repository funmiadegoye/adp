#!/bin/bash

# Bastion Host User Data Script
set -e

# Update system
dnf update -y

# Install basic packages
dnf install -y \
    htop \
    net-tools \
    bind-utils \
    awscli \
    unzip \
    jq \
    git \
    curl

# Install SSM Agent
dnf install -y "https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_amd64/amazon-ssm-agent.rpm"
curl -O "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
dnf install -y session-manager-plugin.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Create SSH directory for ec2-user
mkdir -p /home/ec2-user/.ssh
# Copy the private key into the .ssh directory
echo "${privatekey}" > /home/ec2-user/.ssh/id_rsa
# Set correct permissions and ownership
chmod 400 /home/ec2-user/.ssh/id_rsa
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa

# Configure SSH (security hardening)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-ssh/PermitRootLogin no/' /etc/ssh/sshd_config
echo "AllowUsers ec2-user" >> /etc/ssh/sshd_config
systemctl restart sshd

# Set hostname
hostnamectl set-hostname bastion

# Install New Relic
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
sudo NEW_RELIC_API_KEY="${nr-key}" \
     NEW_RELIC_ACCOUNT_ID="${nr-acc-id}" \
     NEW_RELIC_REGION=EU \
     /usr/local/bin/newrelic install -y

# Clean up
dnf autoremove -y
dnf clean all
rm -f session-manager-plugin.rpm

echo "Bastion host setup completed successfully!"