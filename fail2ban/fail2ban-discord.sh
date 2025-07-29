#!/bin/bash

ACTION=$1
IP=$2
JAIL=$3
FAILURES=$4

# Discord webhook URL
DISCORD_WEBHOOK="discord-webhook-here"
ROLE_ID="role-id-here"

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
                \"text\": \"Fail2Ban Security\"
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
                \"text\": \"Fail2Ban Security\"
            },
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }]
    }"
fi