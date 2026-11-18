#!/usr/bin/env bash
# now-drift-check.sh - UserPromptSubmit hook. Prints today's locked priorities
# and the current focus on every prompt, so a mid-session drift (a new idea that
# is not on today's list) gets named instead of silently followed.
#
# Reads ${CLAUDE_HOME:-$HOME/.claude}/today.md and now.md. Stdout from a
# UserPromptSubmit hook is added to the model's context. Emits only stable text
# (no timestamps) so prompt caching keeps hitting. Silent when both files are
# missing. Fails open: never exits non-zero.

set -u
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
NOW_FILE="$CLAUDE_HOME/now.md"
TODAY_FILE="$CLAUDE_HOME/today.md"

[ -f "$NOW_FILE" ] || [ -f "$TODAY_FILE" ] || exit 0

# Epoch seconds for YYYY-MM-DD on both BSD (macOS) and GNU (Linux) date.
epoch() { date -d "$1" +%s 2>/dev/null || date -j -f %Y-%m-%d "$1" +%s 2>/dev/null || echo 0; }

echo "[focus-check]"

if [ -f "$TODAY_FILE" ]; then
  today_date=$(head -5 "$TODAY_FILE" | sed -n 's/^date: //p')
  if [ "$today_date" = "$(date +%Y-%m-%d)" ]; then
    echo "today.md locked priorities:"
    # Each numbered priority, followed by its verify: hint when the next line has one.
    awk '
      /^[0-9]+\./ { print "  " $0; getline nxt;
                    if (nxt ~ /^[[:space:]]*verify:/) {
                      sub(/^[[:space:]]+/, "", nxt); print "     [" nxt "]"
                    }
                  }
    ' "$TODAY_FILE"
    echo "Verify rule: before working on a priority, run its verify: query first. If it finds matches, the priority may already be done; say so before starting."
  elif [ -z "$today_date" ]; then
    echo "today.md STALE: no 'date:' line in the first 5 lines. Add 'date: $(date +%Y-%m-%d)' or remove the file."
  else
    e=$(epoch "$today_date")
    if [ "$e" -gt 0 ] 2>/dev/null; then
      echo "today.md STALE: dated $today_date ($(( ( $(date +%s) - e ) / 86400 )) days old). Refresh it or remove it."
    else
      echo "today.md STALE: date '$today_date' is not YYYY-MM-DD. Fix or remove."
    fi
  fi
fi

if [ -f "$NOW_FILE" ]; then
  focus=$(sed -n 's/^focus: //p' "$NOW_FILE" | head -1)
  matches=$(sed -n 's/^matches_today_lock: //p' "$NOW_FILE" | head -1)
  [ -n "$focus" ] && echo "now.md focus: ${focus} (matches today=${matches:-unknown})"
fi

echo "Drift rule: if the user's message does not match the focus above, name the pattern (shiny-object, scope-creep, rabbit-hole) and ask one line: pivot, or park it? Then continue."
exit 0
