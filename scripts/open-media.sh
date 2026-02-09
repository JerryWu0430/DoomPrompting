#!/bin/bash
# Opens URLs in separate Chrome windows tiled in 4 corners

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
TEMP_FILE="/tmp/doomprompting-window"
START_FILE="/tmp/doomprompting-start"

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

# Get screen size and calculate quadrants
read screen_width screen_height < <(osascript -e 'tell application "Finder" to get bounds of window of desktop' | awk -F', ' '{print $3, $4}')

half_w=$((screen_width / 2))
half_h=$((screen_height / 2))

# Positions: top-left, top-right, bottom-left, bottom-right
positions=(
  "0 0 $half_w $half_h"
  "$half_w 0 $screen_width $half_h"
  "0 $half_h $half_w $screen_height"
  "$half_w $half_h $screen_width $screen_height"
)

# Clear old window IDs
> "$TEMP_FILE"

# Open each URL in its own window, positioned in a corner
for i in "${!urls[@]}"; do
  url="${urls[$i]}"
  pos_idx=$((i % 4))
  read x1 y1 x2 y2 <<< "${positions[$pos_idx]}"

  window_id=$(osascript <<EOF
tell application "Google Chrome"
  set newWindow to make new window
  set URL of active tab of newWindow to "$url"
  set bounds of newWindow to {$x1, $y1, $x2, $y2}
  return id of newWindow
end tell
EOF
  )

  if [ -n "$window_id" ]; then
    echo "$window_id" >> "$TEMP_FILE"
  fi
done

# Activate Chrome
osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null

# Record start time
if [ -s "$TEMP_FILE" ]; then
  date +%s > "$START_FILE"
fi
