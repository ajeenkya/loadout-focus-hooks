#!/usr/bin/env bash
# test.sh - exercises both hooks and the installer in a throwaway HOME. No network, no real ~/.claude.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "PASS: $1"; }; bad(){ fail=$((fail+1)); echo "FAIL: $1"; }
export HOME="$T/home"; mkdir -p "$HOME"; export CLAUDE_HOME="$HOME/.claude"
"$HERE/install.sh" >/dev/null 2>&1 && [ -x "$CLAUDE_HOME/hooks/now-drift-check.sh" ] && ok "install.sh installs executable hooks" || bad "install"
[ ! -e "$CLAUDE_HOME/settings.json" ] && ok "install.sh leaves settings.json alone" || bad "settings.json touched"
H="$CLAUDE_HOME/hooks/now-drift-check.sh"
[ -z "$("$H")" ] && ok "drift hook is silent with no state files" || bad "drift hook not silent"
printf -- '---\ndate: %s\n---\n1. **Ship the thing.**\n   verify: grep:thing src\n' "$(date +%Y-%m-%d)" > "$CLAUDE_HOME/today.md"
out="$("$H")"; echo "$out" | grep -q "Ship the thing" && echo "$out" | grep -q "\[verify: grep:thing src\]" && ok "drift hook prints today's priority and its verify line" || bad "priority output: $out"
printf -- '---\ndate: %s\n---\n1. **A.**\n2. **B.**\n   verify: grep:b src\n3. **C.**\n' "$(date +%Y-%m-%d)" > "$CLAUDE_HOME/today.md"
out="$("$H")"; echo "$out" | grep -q "1. \*\*A" && echo "$out" | grep -q "2. \*\*B" && echo "$out" | grep -q "3. \*\*C" && echo "$out" | grep -q "\[verify: grep:b src\]" && ok "drift hook prints adjacent priorities (no line swallowed)" || bad "adjacent priorities: $out"
printf -- '---\ndate: 2020-01-01\n---\n' > "$CLAUDE_HOME/today.md"
"$H" | grep -q "STALE: dated 2020-01-01" && ok "drift hook flags a stale today.md" || bad "stale"
printf -- 'focus: write the readme\nmatches_today_lock: no\n' > "$CLAUDE_HOME/now.md"
"$H" | grep -q "now.md focus: write the readme (matches today=no)" && ok "drift hook prints now.md focus" || bad "focus line"
# focus-guard
G="$CLAUDE_HOME/hooks/focus-guard.sh"; export PROJECTS_ROOT="$HOME/projects"
printf 'period:\n  primary: alpha\n  secondary: null\n  hook_mode: block\nparked:\nallowed_concurrent:\n' > "$CLAUDE_HOME/focus.yaml"
mk() { printf '{"tool_input":{"command":"cd %s/projects/%s && ls"}}' "$HOME" "$1"; }
mk beta | "$G" >/dev/null 2>&1; [ $? -eq 2 ] && ok "focus-guard blocks (exit 2) a cd into a non-primary project in block mode" || bad "no block"
mk alpha | "$G" >/dev/null 2>&1; [ $? -eq 0 ] && ok "focus-guard allows the primary project" || bad "primary blocked"
sed -i.bak 's/hook_mode: block/hook_mode: warn/' "$CLAUDE_HOME/focus.yaml"
mk beta | "$G" >/dev/null 2>&1; [ $? -eq 0 ] && ok "focus-guard only warns (exit 0) in warn mode" || bad "warn mode blocked"
printf '{"tool_input":{"command":"ls -la"}}' | "$G" >/dev/null 2>&1; [ $? -eq 0 ] && ok "focus-guard ignores commands that do not cd into a project" || bad "unrelated cmd"
echo "=== $pass passed, $fail failed ==="; [ $fail -eq 0 ]
