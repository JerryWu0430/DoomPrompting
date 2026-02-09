#!/bin/bash
# Opens URLs in a new Chrome window when Claude prompt starts

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
TEMP_FILE="/tmp/doomprompting-window"

# Check if enabled
if [ ! -f "$CONFIG_DIR/enabled" ]; then
  exit 0
fi

# Check if URLs file exists
if [ ! -f "$CONFIG_DIR/urls.txt" ]; then
  exit 0
fi

# Read URLs into array (skip empty lines and comments)
urls=()
while IFS= read -r line || [ -n "$line" ]; do
  line=$(echo "$line" | xargs) # trim whitespace
  [[ -z "$line" || "$line" == \#* ]] && continue
  urls+=("$line")
done < "$CONFIG_DIR/urls.txt"

# Exit if no URLs
if [ ${#urls[@]} -eq 0 ]; then
  exit 0
fi

# Build AppleScript to open new window with all URLs
first_url="${urls[0]}"
remaining_urls=("${urls[@]:1}")

applescript='
tell application "Google Chrome"
  set newWindow to make new window
  set URL of active tab of newWindow to "'"$first_url"'"
'

for url in "${remaining_urls[@]}"; do
  applescript+='
  tell newWindow to make new tab with properties {URL:"'"$url"'"}'
done

applescript+='
  set windowId to id of newWindow
  return windowId
end tell
'

# Run AppleScript and capture window ID
window_id=$(osascript -e "$applescript" 2>/dev/null)

# Store window ID for later cleanup
if [ -n "$window_id" ]; then
  echo "$window_id" > "$TEMP_FILE"
fi
