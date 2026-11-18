#!/usr/bin/env bash
# focus-guard.sh - PreToolUse hook (matcher: Bash). Intervenes on project context-switching.
#
# When a Bash command would cd into a project folder that's NOT the declared
# monthly primary (and not in parked or allowed_concurrent), this hook surfaces
# the shiny-object pattern:
#   warn  -> prints a warning, allows the command (default)
#   block -> exits 2 to block the command, requires explicit acknowledgement
#
# Reads ${CLAUDE_HOME:-$HOME/.claude}/focus.yaml for the current primary +
# allowed_concurrent list. Fails open on any error.
#
# Customize PROJECTS_ROOT below to wherever your projects live.

set +e
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
FOCUS_YAML="$CLAUDE_HOME/focus.yaml"
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Desktop/projects}"

# Read stdin JSON (the harness passes tool input here)
INPUT=$(cat 2>/dev/null || echo "{}")
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# Derive the relative projects path token to match against, e.g. "Desktop/projects"
PROJECTS_REL="${PROJECTS_ROOT#$HOME/}"

# Only intervene on cd into a project folder under PROJECTS_ROOT
if ! echo "$COMMAND" | grep -qE "(cd|pushd) +.*${PROJECTS_REL}/[^/ ]+"; then
  exit 0
fi

# Extract the target project slug
TARGET=$(echo "$COMMAND" | grep -oE "${PROJECTS_REL}/[^/ ]+" | head -1 | sed "s|${PROJECTS_REL}/||")
[ -z "$TARGET" ] && exit 0

# Bail if focus.yaml missing
[ -f "$FOCUS_YAML" ] || exit 0

# Read primary, hook_mode, parked, allowed_concurrent
strip_comment() { sed 's/[[:space:]]*#.*//' | tr -d '"' | tr -d ' '; }

PRIMARY=$(grep -E "^  primary:" "$FOCUS_YAML" | head -1 | awk -F': ' '{print $2}' | strip_comment)
[ "$PRIMARY" = "null" ] && PRIMARY=""

SECONDARY=$(grep -E "^  secondary:" "$FOCUS_YAML" | head -1 | awk -F': ' '{print $2}' | strip_comment)
[ "$SECONDARY" = "null" ] && SECONDARY=""

HOOK_MODE=$(grep -E "^  hook_mode:" "$FOCUS_YAML" | head -1 | awk -F': ' '{print $2}' | strip_comment)
[ -z "$HOOK_MODE" ] && HOOK_MODE="warn"

PARKED=$(awk '/^parked:/{f=1;next} /^[a-z]/{f=0} f && /slug:/{print $3}' "$FOCUS_YAML" 2>/dev/null | sed 's/[[:space:]]*#.*//' | tr '\n' ' ')
ALLOWED=$(awk '/^allowed_concurrent:/{f=1;next} /^[a-z]/{f=0} f && /^  - /{print $2}' "$FOCUS_YAML" 2>/dev/null | sed 's/[[:space:]]*#.*//' | tr '\n' ' ')

[ -z "$PRIMARY" ] && exit 0
[ "$TARGET" = "$PRIMARY" ] && exit 0
[ "$TARGET" = "$SECONDARY" ] && exit 0
echo " $ALLOWED $PARKED " | grep -q " $TARGET " && exit 0

# Otherwise: intervene
SECONDARY_LINE=""
[ -n "$SECONDARY" ] && SECONDARY_LINE="
Secondary:       $SECONDARY (allowed)"

MSG="Focus guard: switching to '$TARGET'. Not primary or secondary this month.

Open right now: $PRIMARY (primary)${SECONDARY_LINE}
Switching to:    $TARGET (not in parked or allowed_concurrent)

Pattern check: is this a real pivot, or shiny-object?
  - Parking primary for this work: edit ${FOCUS_YAML}
  - One-off touch (won't pull focus): add '$TARGET' to allowed_concurrent
  - Genuine pivot: re-declare primary"

if [ "$HOOK_MODE" = "block" ]; then
  echo "$MSG" >&2
  echo "" >&2
  echo "Blocked. Acknowledge above and re-run with intent, or edit focus.yaml." >&2
  exit 2
else
  echo "$MSG" >&2
  echo "" >&2
  echo "(warn mode: command will proceed. Change hook_mode to 'block' to enforce.)" >&2
  exit 0
fi
