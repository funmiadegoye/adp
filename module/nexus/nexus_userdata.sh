#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
NEXUS_USER="nexus"
NEXUS_INSTALL_DIR="/opt/nexus"
NEXUS_DATA_DIR="/opt/sonatype-work"
NEXUS_VERSION="3.80.0-06"
DOWNLOAD_URL="https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"

# 1. Install Java (required by Nexus)
echo "Updating packages..."
sudo dnf update -y

echo "Installing Java..."
sudo dnf install -y java-21-openjdk java-21-openjdk-devel wget

# Install SSM agent and Session Manager plugin
echo "Installing SSM Agent and Session Manager plugin..."
sudo dnf install -y https://s3.eu-west-1.amazonaws.com/amazon-ssm-eu-west-1/latest/linux_amd64/amazon-ssm-agent.rpm
curl -s "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
sudo yum install -y session-manager-plugin.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# 2. Add nexus user
echo "Adding nexus user..."
if ! id -u ${NEXUS_USER} >/dev/null 2>&1; then
  sudo useradd -r -M -d ${NEXUS_INSTALL_DIR} -s /bin/false ${NEXUS_USER}
fi
sudo usermod -d ${NEXUS_INSTALL_DIR} ${NEXUS_USER}

# 3. Download and extract Nexus
echo "Downloading Nexus ${NEXUS_VERSION}..."
cd /tmp
sudo wget -O nexus.tar.gz ${DOWNLOAD_URL}
sudo tar -xzf nexus.tar.gz

# 4. Move Nexus to /opt and set permissions
echo "Moving Nexus to ${NEXUS_INSTALL_DIR}..."
sudo mv nexus-${NEXUS_VERSION} ${NEXUS_INSTALL_DIR}
sudo mv sonatype-work ${NEXUS_DATA_DIR}

# Ensure permissions and executability
echo "Setting permissions..."
sudo chmod +x ${NEXUS_INSTALL_DIR}/bin/nexus
sudo chmod +x /opt
sudo chmod -R u+rx ${NEXUS_INSTALL_DIR}/bin
sudo chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_INSTALL_DIR}
sudo chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_DATA_DIR}

# 5. Configure Nexus to run as nexus user
echo "Configuring Nexus to run as ${NEXUS_USER}..."
echo "run_as_user=${NEXUS_USER}" | sudo tee ${NEXUS_INSTALL_DIR}/bin/nexus.rc

# 6. Create systemd service file
echo "Creating systemd service..."
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=${NEXUS_INSTALL_DIR}/bin/nexus start
ExecStop=${NEXUS_INSTALL_DIR}/bin/nexus stop
User=${NEXUS_USER}
Restart=on-abort
Environment=HOME=${NEXUS_INSTALL_DIR}
WorkingDirectory=${NEXUS_INSTALL_DIR}

[Install]
WantedBy=multi-user.target
EOF

# 7. Handle SELinux
echo "Checking SELinux status..."
SELINUX_STATUS=$(getenforce)

if [[ "$SELINUX_STATUS" == "Enforcing" ]]; then
  echo "Disabling SELinux temporarily and permanently..."
  sudo setenforce 0
  sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
fi

# 8. Enable and start the Nexus service
echo "Starting Nexus service..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# 9. Show Nexus status and password info
echo "✅ Nexus ${NEXUS_VERSION} is installed and running on port 8081"
echo "👉 Check status: sudo systemctl status nexus"
echo "🔑 Default admin password is stored at: ${NEXUS_DATA_DIR}/nexus3/admin.password"
