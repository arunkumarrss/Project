#!/bin/sh
set -eu  # Removed 'pipefail'

# ------------------ Configuration ------------------
DISK_THRESHOLD=80       # %
UPTIME_LIMIT=1         # in hours
LOAD_THRESHOLD=5.0      # 1-min load average
EMAIL="alerttest@infinitisoftware.net"

# SMTP settings
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
USER="notify-internal@infinitisoftware.net"
PASS="uviartguvmetuujh"

FROM="notify-internal@infinitisoftware.net"
TO="$EMAIL"
SUBJECT="🚨 System Alerts from $(hostname)"

# ------------------ Runtime Variables ------------------
DATE=$(date +"%A %B %d %T")
HOSTNAME=$(hostname)
USERNAME=$(who | awk '{print $1}' | grep -v '^root$' | head -n1)

DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_TOTAL=$(df -h --total | grep total | awk '{print $2}')
DISK_USED=$(df -h --total | grep total | awk '{print $3}')
DISK_AVAIL=$(df -h --total | grep total | awk '{print $4}')

RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
RAM_USED=$(free -h | awk '/Mem:/ {print $3}')
RAM_FREE=$(free -h | awk '/Mem:/ {print $4}')

UPTIME=$(awk '{print int($1/3600)}' /proc/uptime)

LOAD_AVG=$(uptime | awk -F 'load average: ' '{print $2}')
LOAD_1MIN=$(echo "$LOAD_AVG" | cut -d',' -f1)
LOAD_HIGH=$(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc)

# ------------------ Alert Check ------------------
if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ] || [ "$UPTIME" -ge "$UPTIME_LIMIT" ] || [ "$LOAD_HIGH" -eq 1 ]; then

    # Use temporary file for message body
    BODY_FILE=$(mktemp)
    {
        echo "Timing    : $DATE"
        echo "Username  : $USERNAME"
        echo "Hostname  : $HOSTNAME"
        echo " - Disk usage: $DISK_USAGE% (Total: $DISK_TOTAL, Used: $DISK_USED, Available: $DISK_AVAIL)"
        echo " - RAM usage : Total: $RAM_TOTAL, Used: $RAM_USED, Free: $RAM_FREE"
        echo " - Uptime    : $UPTIME hours"
        echo " - Load avg  : $LOAD_AVG"
        echo ""
        echo "Regards,"
        echo "Infra-Team"
    } > "$BODY_FILE"

    USER_B64=$(printf "%s" "$USER" | openssl base64 -A)
    PASS_B64=$(printf "%s" "$PASS" | openssl base64 -A)

    (
        sleep 1
        echo "EHLO $(hostname)"
        sleep 1
        echo "STARTTLS"
        sleep 2
        echo "EHLO $(hostname)"
        sleep 1
        echo "AUTH LOGIN"
        sleep 1
        echo "$USER_B64"
        sleep 1
        echo "$PASS_B64"
        sleep 1
        echo "MAIL FROM:<$FROM>"
        sleep 1
        echo "RCPT TO:<$TO>"
        sleep 1
        echo "DATA"
        sleep 1
        printf "Subject: %s\r\nFrom: %s\r\nTo: %s\r\n\r\n" "$SUBJECT" "$FROM" "$TO"
        cat "$BODY_FILE"
        echo "."
        sleep 1
        echo "QUIT"
    ) | openssl s_client -quiet -starttls smtp -crlf -connect "$SMTP_SERVER:$SMTP_PORT"

    rm -f "$BODY_FILE"
fi

