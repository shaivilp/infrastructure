# Fail2ban with Discord Notifications Setup Guide

This guide covers setting up fail2ban with Discord webhook notifications for SSH protection on Ubuntu.

## Prerequisites

- Ubuntu server with SSH access
- Discord server with webhook permissions
- Root or sudo access

## Step 1: Install Fail2ban

```bash
sudo apt update
sudo apt install fail2ban -y
```

## Step 2: Create Discord Webhook

1. In Discord, go to your server
2. Server Settings → Integrations → Webhooks
3. Click "New Webhook"
4. Name it (e.g., "Fail2Ban Alerts")
5. Choose the channel for notifications
6. Copy the webhook URL (you'll need this later)

### Getting Role ID (for mentions)
1. In Discord: User Settings → Advanced → Enable "Developer Mode"
2. Right-click the role you want to ping → "Copy Role ID"

## Step 3: Install Dependencies

```bash
# Install whois for IP location info (optional but recommended)
sudo apt install whois -y


## Step 4: Create Discord Notification Script

```bash
sudo nano /usr/local/bin/fail2ban-discord.sh
```

Add this content (replace webhook URL and role ID):

```bash
#!/bin/bash

ACTION=$1
IP=$2
JAIL=$3
FAILURES=$4

# Discord webhook URL
DISCORD_WEBHOOK="webhookhere"
ROLE_ID="discordroleidhere"

F2B_UPTIME=$(systemctl show fail2ban.service --property=ActiveEnterTimestampMonotonic | cut -d= -f2)
CURRENT_TIME=$(date +%s%N | cut -b1-16)
UPTIME_SECONDS=$(( ($CURRENT_TIME - $F2B_UPTIME) / 1000000 ))

# Skip notifications if fail2ban started less than 60 seconds ago
if [ $UPTIME_SECONDS -lt 60 ]; then
    exit 0
fi

# Get additional info
HOSTNAME=$(hostname)
DATE=$(date)
WHOIS_INFO=$(whois $IP 2>/dev/null | grep -E "country:|org-name:|OrgName:" | head -3 | tr '\n' ' ')

if [ "$ACTION" = "ban" ]; then
    # Discord notification for ban
    curl -X POST $DISCORD_WEBHOOK \
    -H "Content-Type: application/json" \
    -d "{
        \"content\": \"<@&$ROLE_ID>\",
        \"embeds\": [{
            \"title\": \"🚫 SSH Attack Blocked\",
            \"color\": 15158332,
            \"fields\": [
                {\"name\": \"IP Address\", \"value\": \"\`$IP\`\", \"inline\": true},
                {\"name\": \"Failed Attempts\", \"value\": \"$FAILURES\", \"inline\": true},
                {\"name\": \"Server\", \"value\": \"$HOSTNAME\", \"inline\": true},
                {\"name\": \"Jail\", \"value\": \"$JAIL\", \"inline\": true},
                {\"name\": \"Time\", \"value\": \"$DATE\", \"inline\": false},
                {\"name\": \"Location Info\", \"value\": \"$WHOIS_INFO\", \"inline\": false}
            ],
            \"footer\": {
                \"text\": \"Vici Sports Science | Fail2Ban Security\"
            },
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }]
    }"

elif [ "$ACTION" = "unban" ]; then
    # Discord notification for unban
    curl -X POST $DISCORD_WEBHOOK \
    -H "Content-Type: application/json" \
    -d "{
        \"content\": \"<@&$ROLE_ID>\",
        \"embeds\": [{
            \"title\": \"✅ IP Unbanned\",
            \"color\": 3066993,
            \"fields\": [
                {\"name\": \"IP Address\", \"value\": \"\`$IP\`\", \"inline\": true},
                {\"name\": \"Server\", \"value\": \"$HOSTNAME\", \"inline\": true},
                {\"name\": \"Jail\", \"value\": \"$JAIL\", \"inline\": true},
                {\"name\": \"Time\", \"value\": \"$DATE\", \"inline\": false}
            ],
            \"footer\": {
                \"text\": \"Vici Sports Science | Fail2Ban Security\"
            },
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }]
    }"
fi
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/fail2ban-discord.sh
```

## Step 5: Create Discord Action for Fail2ban

```bash
sudo nano /etc/fail2ban/action.d/discord.conf
```

Add this content:

```ini
[Definition]
# Action to send Discord notifications

actionstart = /usr/local/bin/fail2ban-discord.sh start "<name>" "<name>" "0"
actionstop = /usr/local/bin/fail2ban-discord.sh stop "<name>" "<name>" "0"
actionban = /usr/local/bin/fail2ban-discord.sh ban <ip> <name> <failures>
actionunban = /usr/local/bin/fail2ban-discord.sh unban <ip> <name> "0"

[Init]
name = default
```

## Step 6: Configure Fail2ban Jail

```bash
sudo nano /etc/fail2ban/jail.local
```

Add this configuration:

```ini
[DEFAULT]
# Ban duration (1 hour)
bantime = 3600

# Time window to look for failures (10 minutes)
findtime = 600

# Number of failures before ban
maxretry = 3

# Whitelist IPs - Add your IPs here
# Includes localhost, Tailscale CGNAT range
ignoreip = 127.0.0.1/8 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48 YOUR_HOME_IP YOUR_OFFICE_IP

# Use Discord notifications
action = discord[name=%(__name__)s]

# Backend for log monitoring
backend = auto

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

[sshd-aggressive]
# Bans IPs using invalid usernames immediately
enabled = true
port = ssh
filter = sshd[mode=aggressive]
logpath = /var/log/auth.log
maxretry = 1
bantime = 86400  # 24 hours
findtime = 3600
```

## Step 7: Configure Persistent Database

```bash
sudo nano /etc/fail2ban/fail2ban.local
```

Add this content:

```ini
[Definition]
# Persistent database to maintain bans across restarts
dbfile = /var/lib/fail2ban/fail2ban.sqlite3
dbpurgeage = 7d

# Log level
loglevel = INFO
logtarget = /var/log/fail2ban.log
```

## Step 8: Start and Enable Fail2ban

```bash
# Enable fail2ban to start on boot
sudo systemctl enable fail2ban

# Start fail2ban
sudo systemctl start fail2ban

# Check status
sudo systemctl status fail2ban
```

## Step 9: Test the Setup

```bash
# Test Discord notification
sudo fail2ban-client set sshd banip 192.0.2.1

# Check Discord for the notification

# Unban the test IP
sudo fail2ban-client set sshd unbanip 192.0.2.1

# View all banned IPs
sudo fail2ban-client get sshd banned
```

## Useful Commands

### Monitor Fail2ban

```bash
# Check fail2ban status
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd

# Watch fail2ban logs
sudo tail -f /var/log/fail2ban.log

# Watch SSH authentication logs
sudo tail -f /var/log/auth.log | grep sshd
```

### Manage Bans

```bash
# Ban an IP manually
sudo fail2ban-client set sshd banip 192.168.1.100

# Unban an IP
sudo fail2ban-client set sshd unbanip 192.168.1.100

# Add IP to whitelist
sudo fail2ban-client set sshd addignoreip 192.168.1.50

# Remove from whitelist
sudo fail2ban-client set sshd delignoreip 192.168.1.50
```

### Database Management

```bash
# View bans in database
sudo sqlite3 /var/lib/fail2ban/fail2ban.sqlite3 "SELECT jail, ip, timeofban, bantime FROM bans;"

# Check ban history
sudo sqlite3 /var/lib/fail2ban/fail2ban.sqlite3 "SELECT ip, COUNT(*) as ban_count FROM bans GROUP BY ip ORDER BY ban_count DESC LIMIT 10;"
```

## Troubleshooting

### Discord notifications not working

1. Check webhook URL is correct
2. Test script manually:
   ```bash
   sudo /usr/local/bin/fail2ban-discord.sh ban 1.2.3.4 sshd 5
   ```
3. Check curl is installed: `sudo apt install curl -y`

### Bans not persisting

1. Check database exists:
   ```bash
   ls -la /var/lib/fail2ban/fail2ban.sqlite3
   ```
2. Verify database configuration:
   ```bash
   sudo fail2ban-client get dbfile
   ```

### Too many notifications on restart

The script includes a 30-second startup delay to prevent spam. If needed, increase the timeout in the script.

## Security Notes

1. **Replace placeholder IPs** in `ignoreip` with your actual IP addresses
2. **Keep webhook URL secret** - anyone with it can send messages to your Discord
3. **Monitor banned IPs regularly** to ensure legitimate users aren't blocked
4. **Review logs periodically** for attack patterns
5. **Update whitelisted IPs** when your IP changes

## Maintenance

- Logs rotate automatically via logrotate
- Database purges old entries based on `dbpurgeage` setting
- Monitor disk space for logs: `/var/log/fail2ban.log`
- Update fail2ban regularly: `sudo apt update && sudo apt upgrade fail2ban`