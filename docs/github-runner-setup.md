# Secure GitHub Actions Self-Hosted Runner Setup

```bash
# Create a new user for the runner
sudo useradd -m -s /bin/bash github-runner
sudo passwd -d github-runner
sudo usermod -s /usr/sbin/nologin github-runner
```

```bash
# Install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl jq unzip git
```

```bash
# Switch to runner user
sudo su - github-runner
```

```bash
# Download and extract the GitHub Actions runner
mkdir -p ~/actions-runner && cd ~/actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.315.0/actions-runner-linux-x64-2.315.0.tar.gz
tar xzf actions-runner-linux-x64-2.315.0.tar.gz
```

Go to https://github.com > your repo > Settings > Actions > Runners > New self-hosted runner. Select Linux and x64. Copy the registration command with your token. Replace OWNER and REPO and run it:

```bash
./config.sh --url https://github.com/OWNER/REPO --token YOUR_TOKEN --name secure-runner --unattended --labels self-hosted,secure
```

```bash
# Exit to root
exit
```

```bash
# Create systemd service
sudo nano /etc/systemd/system/github-runner.service
```

Paste this in full:

```ini
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
User=github-runner
WorkingDirectory=/home/github-runner/actions-runner
ExecStart=/bin/bash /home/github-runner/actions-runner/run.sh
Restart=always
RestartSec=5
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ProtectSystem=full
ProtectHome=no
PrivateTmp=true
ProtectKernelModules=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ReadOnlyPaths=/root /etc /usr /lib
ReadWritePaths=/home/github-runner/actions-runner /home/github-runner/.npm

[Install]
WantedBy=multi-user.target
```

```bash
# Reload and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable github-runner
sudo systemctl start github-runner
```

```bash
# Check status and logs
systemctl status github-runner
journalctl -u github-runner -f
```

```bash
# Optional firewall setup
sudo ufw default deny incoming
sudo ufw allow OpenSSH
sudo ufw allow out 443
sudo ufw enable
```

```bash
# Manual runner update
sudo systemctl stop github-runner
sudo su - github-runner
cd ~/actions-runner
./config.sh remove --token <TOKEN>
exit
```

```bash
# Full removal
sudo systemctl stop github-runner
sudo systemctl disable github-runner
sudo rm /etc/systemd/system/github-runner.service
sudo userdel -r github-runner
```

Reference:
https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners
