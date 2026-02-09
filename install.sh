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

# Create sessions log if not exists
touch "$SCRIPT_DIR/config/sessions.log"

# Make scripts executable
chmod +x "$SCRIPT_DIR/scripts/"*.sh
chmod +x "$SCRIPT_DIR/scripts/doom"

# Create symlink for doom CLI
if [ -w "/usr/local/bin" ]; then
  ln -sf "$SCRIPT_DIR/scripts/doom" /usr/local/bin/doom
  echo "Symlinked: doom -> /usr/local/bin/doom"
else
  echo "Note: Add $SCRIPT_DIR/scripts to PATH or run:"
  echo "  sudo ln -s $SCRIPT_DIR/scripts/doom /usr/local/bin/doom"
fi

# Define the hooks to add
# Open on submit; close only on Stop (not PreToolUse, so the window stays open until you stop the response)
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
echo "  doom list       - Show URLs"
echo "  doom add <url>  - Add URL"
echo "  doom disable N  - Disable URL #N"
echo "  doom enable N   - Enable URL #N"
echo "  doom toggle     - Global on/off"
echo "  doom log        - Session history"
echo "  doom stats      - Total time summary"
