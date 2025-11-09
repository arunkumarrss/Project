# System Alert Notification Script

This Bash script monitors critical system metrics and sends email alerts if certain thresholds are exceeded. It is designed to keep system administrators informed about disk usage, RAM usage, uptime, and CPU load.

---

## Features

- Monitors disk usage and triggers alerts if it exceeds a defined threshold.
- Monitors system uptime and triggers alerts if it exceeds a defined limit.
- Monitors CPU load and triggers alerts if it exceeds a defined threshold.
- Sends email notifications via Gmail SMTP.
- Includes detailed system information such as hostname, logged-in user, disk usage, RAM usage, uptime, and load average.

---

## Prerequisites

- Linux/Unix system with Bash
- Required commands: `df`, `free`, `uptime`, `who`, `awk`, `bc`
- Internet access to send emails via SMTP
- Gmail account with **App Password** enabled for SMTP

