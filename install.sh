#!/usr/bin/env bash
# install.sh - copy the three files into ~/.claude. Backs up anything it would overwrite.
# Never edits settings.json; it prints the snippet to paste instead.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CLAUDE_HOME:-$HOME/.claude}"
TS="$(date +%Y%m%d%H%M%S)"
mkdir -p "$CH/hooks" "$CH/rules"
put() { # put <src> <dst>
  [ -f "$2" ] && ! cmp -s "$1" "$2" && cp "$2" "$2.bak.$TS" && echo "backed up $2 -> $2.bak.$TS"
  cp "$1" "$2"; echo "installed $2"
}
put "$HERE/hooks/now-drift-check.sh" "$CH/hooks/now-drift-check.sh"
put "$HERE/hooks/focus-guard.sh"     "$CH/hooks/focus-guard.sh"
put "$HERE/rules/lesson-routing.md"  "$CH/rules/lesson-routing.md"
chmod +x "$CH/hooks/now-drift-check.sh" "$CH/hooks/focus-guard.sh"
[ -f "$CH/today.md" ]  || { cp "$HERE/examples/today.md.example" "$CH/today.md.example"; }
[ -f "$CH/focus.yaml" ] || { cp "$HERE/examples/focus.yaml.example" "$CH/focus.yaml.example"; }
cat <<MSG

Next, two steps (this script does not touch settings.json):
1. Add to $CH/settings.json under "hooks":
   "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "$CH/hooks/now-drift-check.sh"}]}],
   "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "$CH/hooks/focus-guard.sh"}]}]
2. cp $CH/today.md.example $CH/today.md   (set today's date and three priorities)
   cp $CH/focus.yaml.example $CH/focus.yaml   (optional, for focus-guard)
To remove: delete the two hook files and the rule file; nothing else was changed.
MSG
