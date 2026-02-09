#!/bin/bash
# Toggle DoomPrompting on/off

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

if [ -f "$CONFIG_DIR/enabled" ]; then
  rm "$CONFIG_DIR/enabled" && echo "DoomPrompting: OFF"
else
  touch "$CONFIG_DIR/enabled" && echo "DoomPrompting: ON"
fi
