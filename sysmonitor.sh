#!/bin/bash

BACKUP_SRC="/home/pavin/Panda/Python/"
LOG_FILE="/var/log/system_health.log"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# CPU and Memory Monitoring
monitor_cpu_memory() {
    log_message "Monitoring CPU and Memory Usage..."
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
    mem_usage=$(free -m | awk 'NR==2{printf "%.2f%", $3*100/$2 }')
    log_message "CPU Usage: $cpu_usage"
    log_message "Memory Usage: $mem_usage"
}

# Top 5 Memory-consuming Processes
list_top_processes() {
    log_message "Top 5 Memory-Consuming Processes:"
    ps aux --sort=-%mem | awk 'NR<=5{print $0}' | tee -a "$LOG_FILE"
}

# System Updates Check
check_system_updates() {
    log_message "Checking for System Updates..."
    if [ -x "$(command -v apt-get)" ]; then
        available_updates=$(apt-get -s upgrade | grep -P '^\d+ upgraded' | awk '{print $1}')
        log_message "Available Updates: $available_updates packages."
    elif [ -x "$(command -v yum)" ]; then
        available_updates=$(yum check-update | wc -l)
        log_message "Available Updates: $available_updates packages."
    else
        log_message "Update check failed: Unsupported package manager."
    fi
}

# Backup Important Files
backup_files() {
    log_message "Starting Backup..."
    if [ -z "$1" ]; then
        read -p "Enter backup destination path: " BACKUP_DEST
    else
        BACKUP_DEST="$1"
    fi
    rsync -avh --delete "$BACKUP_SRC" "$BACKUP_DEST" >> "$LOG_FILE" 2>&1
    log_message "Backup completed to $BACKUP_DEST"
}

# Main Function
main() {
    log_message "Starting System Health Check..."
    monitor_cpu_memory
    list_top_processes
    check_system_updates
    backup_files "$1"
    log_message "System Health Check Complete."
}


main "$1"
