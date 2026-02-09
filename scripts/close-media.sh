#!/bin/bash
# Closes the Chrome window opened by open-media.sh

TEMP_FILE="/tmp/doomprompting-window"

# Check if window ID file exists
if [ ! -f "$TEMP_FILE" ]; then
  exit 0
fi

window_id=$(cat "$TEMP_FILE")

# Close the window by ID
if [ -n "$window_id" ]; then
  osascript -e '
    tell application "Google Chrome"
      repeat with w in windows
        if id of w is '"$window_id"' then
          close w
          exit repeat
        end if
      end repeat
    end tell
  ' 2>/dev/null
fi

# Clean up temp file
rm -f "$TEMP_FILE"
