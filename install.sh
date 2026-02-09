#!/bin/bash
# Install DoomPrompting hooks into Claude Code

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.backup.$(date +%Y%m%d%H%M%S)"

echo "Installing DoomPrompting..."

# Ensure .claude directory exists
mkdir -p "$HOME/.claude"

# Create enabled file (default on)
touch "$SCRIPT_DIR/config/enabled"

# Make scripts executable
chmod +x "$SCRIPT_DIR/scripts/"*.sh

# Define the hooks to add
HOOKS_JSON=$(cat <<EOF
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$SCRIPT_DIR/scripts/open-media.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$SCRIPT_DIR/scripts/close-media.sh"
          }
        ]
      }
    ]
  }
}
EOF
)

# If settings file exists, backup and merge
if [ -f "$CLAUDE_SETTINGS" ]; then
  echo "Backing up existing settings to $BACKUP_FILE"
  cp "$CLAUDE_SETTINGS" "$BACKUP_FILE"

  # Check if jq is available
  if command -v jq &> /dev/null; then
    # Merge hooks using jq
    jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" <(echo "$HOOKS_JSON") > "$CLAUDE_SETTINGS.tmp"
    mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
  else
    echo "Warning: jq not found. Please manually merge hooks config."
    echo "Hooks JSON:"
    echo "$HOOKS_JSON"
    exit 1
  fi
else
  # Create new settings file
  echo "$HOOKS_JSON" > "$CLAUDE_SETTINGS"
fi

echo "Done! Restart Claude Code session to activate."
echo ""
echo "Commands:"
echo "  Toggle: $SCRIPT_DIR/scripts/toggle.sh"
echo "  Edit URLs: $SCRIPT_DIR/config/urls.txt"
