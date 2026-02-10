#!/bin/bash
# Opens URLs in separate Chrome windows across all displays

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
TEMP_FILE="/tmp/doomprompting-window"
START_FILE="/tmp/doomprompting-start"
SESSION_FILE="/tmp/doomprompting-session"

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

# Get all screen bounds using JXA (JavaScript for Automation)
screen_bounds=$(osascript -l JavaScript <<'JSEOF'
ObjC.import('AppKit')
var screens = $.NSScreen.screens
var result = []
for (var i = 0; i < screens.count; i++) {
  var frame = screens.objectAtIndex(i).frame
  var x = frame.origin.x
  var y = frame.origin.y
  var w = frame.size.width
  var h = frame.size.height
  result.push(Math.round(x) + " " + Math.round(y) + " " + Math.round(w) + " " + Math.round(h))
}
result.join("\n")
JSEOF
)

# Parse screen bounds into array
screens=()
while IFS= read -r line; do
  [[ -n "$line" ]] && screens+=("$line")
done <<< "$screen_bounds"

num_screens=${#screens[@]}
if [ $num_screens -eq 0 ]; then
  exit 1
fi

# Create new session ID
session_id=$(date +%s%N)
echo "$session_id" > "$SESSION_FILE"

# Clear old window IDs
> "$TEMP_FILE"

# Get main screen height for Y coordinate conversion
main_height=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); Math.round($.NSScreen.mainScreen.frame.size.height)')

# Build positions: 2 side-by-side slots per screen
positions=()
for screen_data in "${screens[@]}"; do
  read sx sy sw sh <<< "$screen_data"
  half_w=$((sw / 2))

  y1=$(echo "$main_height - $sy - $sh" | bc)
  y2=$(echo "$main_height - $sy" | bc)

  # Left half
  positions+=("$sx $y1 $((sx + half_w)) $y2")
  # Right half
  positions+=("$((sx + half_w)) $y1 $((sx + sw)) $y2")
done

num_positions=${#positions[@]}

# Open each URL in its own window
for i in "${!urls[@]}"; do
  url="${urls[$i]}"
  pos_idx=$((i % num_positions))
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
