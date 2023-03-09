#!/bin/bash

# Set variables
LOG_FILE="/path/to/adpatch.log"
ERROR_FILE="/path/to/errors.txt"
EMAIL_RECIPIENT="youremail@example.com"

# Use grep to find lines in the log file that contain "ERROR"
grep "ERROR" "$LOG_FILE" > "$ERROR_FILE"

# If there are errors, send an email with the error file as an attachment
if [ -s "$ERROR_FILE" ]; then
  echo "Errors were found in adpatch log file. Please see attached." | mail -s "Adpatch errors" -a "$ERROR_FILE" "$EMAIL_RECIPIENT"
fi

# Clean up error file
rm "$ERROR_FILE"
