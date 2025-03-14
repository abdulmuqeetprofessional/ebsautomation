#!/bin/bash
# Script Name: generate_jars.sh
# Purpose: Automate JAR file generation in Oracle EBS R12.2
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
    . ./EBSapps.env RUN
else
    echo "ERROR: EBSapps.env not found in $HOME"
    exit 1
fi

# Variables
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_DIR="$HOME/logs"
LOG_FILE="${LOG_DIR}/jar_generation_${TIMESTAMP}.log"
DEFAULTS_FILE="$APPL_TOP/admin/$TWO_TASK/adalldefaults.txt"
WORKERS=32
MENU_OPTION="GEN_JARS"

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

# Start JAR generation
log_message "Starting JAR file generation..."
log_message "Using defaults file: $DEFAULTS_FILE"
log_message "Number of workers: $WORKERS"

# Execute adadmin command
adadmin defaultsfile="$DEFAULTS_FILE" \
    logfile="$LOG_FILE" \
    workers="$WORKERS" \
    menu_option="$MENU_OPTION" 2>&1 | tee -a "$LOG_FILE"

# Check exit status
if [ $? -eq 0 ]; then
    log_message "JAR generation completed successfully"
else
    log_message "ERROR: JAR generation failed"
    exit 1
fi

# Validate generated JAR files (optional)
log_message "Validating generated JAR files..."
JAR_DIR="$JAVA_TOP"  # Adjust this path based on your environment
if [ -d "$JAR_DIR" ]; then
    JAR_COUNT=$(find "$JAR_DIR" -name "*.jar" | wc -l)
    log_message "Found $JAR_COUNT JAR files in $JAR_DIR"
else
    log_message "WARNING: JAR directory not found at $JAR_DIR"
fi

log_message "Script execution completed"
exit 0
