#!/bin/bash
#Author: Abdul Muqeet
# Script Name: compile_invalid_objects.sh
# Purpose: Automate compilation of invalid objects in Oracle EBS R12.2
# Author: Abdul Muqeet
# Created: March 14, 2025

# Environment setup
echo "Setting up environment..."
cd "$HOME" || {
    echo "ERROR: Cannot change to home directory"
    exit 1
}
# Source EBS environment for RUN filesystem
if [ -f "EBSapps.env" ]; then
    . "$HOME/EBSapps.env" run
else
    echo "ERROR: EBSapps.env not found in $HOME"
    exit 1
fi

# Variables
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_DIR="$HOME/logs"
LOG_FILE="${LOG_DIR}/compile_invalids_${TIMESTAMP}.log"
DEFAULTS_FILE="$APPL_TOP/admin/$TWO_TASK/adalldefaults.txt"
WORKERS=32
MENU_OPTION="CMP_INVALID"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if environment variables are set
if [ -z "$APPL_TOP" ] || [ -z "$TWO_TASK" ]; then
    log_message "ERROR: Environment variables not properly set"
    exit 1
fi

# Check if defaults file exists
if [ ! -f "$DEFAULTS_FILE" ]; then
    log_message "ERROR: Defaults file not found at $DEFAULTS_FILE"
    exit 1
fi

# Start compilation process
log_message "Starting invalid objects compilation..."
log_message "Using defaults file: $DEFAULTS_FILE"
log_message "Number of workers: $WORKERS"

# Execute adadmin command to compile invalid objects
adadmin defaultsfile="$DEFAULTS_FILE" \
    logfile="$LOG_FILE" \
    workers="$WORKERS" \
    menu_option="$MENU_OPTION" 2>&1 | tee -a "$LOG_FILE"

# Check exit status
if [ $? -eq 0 ]; then
    log_message "Invalid objects compilation completed successfully"
else
    log_message "ERROR: Invalid objects compilation failed"
    exit 1
fi

# Optional: Validate remaining invalid objects
log_message "Checking for remaining invalid objects..."
INVALID_COUNT=$(sqlplus -s /nolog <<EOF | grep -v "^$" | tail -n 1
connect apps/$APPS_PWD
set heading off
select count(*) from dba_objects where status = 'INVALID';
EOF
)

if [ -n "$INVALID_COUNT" ]; then
    log_message "Found $INVALID_COUNT invalid objects after compilation"
    if [ "$INVALID_COUNT" -gt 0 ]; then
        log_message "WARNING: Some objects remain invalid"
    else
        log_message "Success: No invalid objects remaining"
    fi
else
    log_message "WARNING: Could not verify invalid object count"
fi

log_message "Script execution completed"
exit 0
