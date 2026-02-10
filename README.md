# DoomPrompting

Automatically opens distracting media while Claude thinks. Windows close when response finishes.

**Why?** You're gonna doomscroll anyway. Might as well automate it.

## How it works

1. You send a prompt to Claude Code
2. Chrome windows open in 4 corners (YouTube, Instagram, TikTok, Reddit)
3. Claude finishes responding
4. Windows auto-close

Session time is logged for shame/accountability.

## Install

```bash
# Clone
git clone https://github.com/youruser/DoomPrompting
cd DoomPrompting

# Install (requires jq)
./install.sh

# Restart Claude Code
```

## CLI

```bash
doom list          # Show URLs with status
doom add <url>     # Add URL
doom disable 2     # Disable URL #2
doom enable 2      # Re-enable URL #2
doom toggle        # Global on/off
doom log           # Recent sessions
doom stats         # Total time wasted
```

## Config

URLs: `config/urls.txt`
```
https://www.youtube.com/shorts
https://www.instagram.com/reels/
https://www.tiktok.com
https://reddit.com
```

Comment out to disable: `#https://reddit.com`

## Requirements

- macOS (uses AppleScript)
- Google Chrome
- Claude Code
- jq (for install)

## Files

```
scripts/
  open-media.sh   # Opens Chrome windows in 4 corners
  close-media.sh  # Closes tracked windows
  toggle.sh       # Enable/disable
  doom            # CLI tool
config/
  urls.txt        # URLs to open
  enabled         # Exists = enabled
  sessions.log    # Session durations
```

## Hooks

Installed to `~/.claude/settings.json`:
- `UserPromptSubmit` → open-media.sh
- `Stop` → close-media.sh

## Uninstall

Remove hooks from `~/.claude/settings.json` and delete the repo.

## License

MIT
