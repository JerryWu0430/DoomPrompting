#!/bin/bash
# Closes Chrome windows opened by open-media.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
TEMP_FILE="/tmp/doomprompting-window"
START_FILE="/tmp/doomprompting-start"
SESSIONS_LOG="$CONFIG_DIR/sessions.log"

# Check if window ID file exists
if [ ! -f "$TEMP_FILE" ]; then
  exit 0
fi

# Close each window by ID
while IFS= read -r window_id; do
  window_id=$(echo "$window_id" | tr -d '[:space:]')
  [[ -z "$window_id" || ! "$window_id" =~ ^[0-9]+$ ]] && continue

  osascript 2>/dev/null <<EOF
tell application "Google Chrome"
  if (exists window id $window_id) then
    close window id $window_id
  end if
end tell
EOF
done < "$TEMP_FILE"

# Clean up temp file
rm -f "$TEMP_FILE"

# Log session duration
if [ -f "$START_FILE" ]; then
  start_time=$(cat "$START_FILE")
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  timestamp=$(date -r "$start_time" +%Y-%m-%dT%H:%M:%S)
  echo "$timestamp duration=${duration}s" >> "$SESSIONS_LOG"
  rm -f "$START_FILE"
fi
