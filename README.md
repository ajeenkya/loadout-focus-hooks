# Claude Code drift hooks (free slice of Loadout)

Two hooks and one rule file for Claude Code. They are plain bash and markdown, MIT licensed, and
install into `~/.claude/` without touching your `settings.json`.

## The problem

You sit down to ship one thing. By 2pm you are deep in something else, and Claude Code followed you
there without saying a word, because nothing in a default install notices that the work changed. A rule
in a prompt ("stay on task") is a request. A rule in a hook is a wall.

## What is in here

| File | Event | What it does |
|---|---|---|
| `hooks/now-drift-check.sh` | UserPromptSubmit | Prints today's three locked priorities and the current focus on every prompt. If your message does not match, the model is told to name the pattern (shiny object, scope creep, rabbit hole) and ask: pivot, or park it? Warns when `today.md` is stale. |
| `hooks/focus-guard.sh` | PreToolUse (Bash) | When a command does `cd` into a project folder that is not your declared primary, it warns, or in `block` mode stops the command (exit 2) and returns the reason to Claude. Reads a small `focus.yaml`. |
| `rules/lesson-routing.md` | rule file | Three questions that decide where a lesson is stored (code comment, stack rules file, existing memory file) so your memory index grows with your systems, not with your lesson count. |

All hooks fail open: on any error they exit 0 and stay out of the way.

## Install (one command)

```bash
git clone <REPO_URL> && cd <REPO_DIR> && ./install.sh
```

It backs up any file it would overwrite, never edits `settings.json`, and prints the two lines to
paste there. Then set today's priorities: `cp ~/.claude/today.md.example ~/.claude/today.md`.
Run `./test.sh` to see both hooks exercised in a throwaway HOME (10 checks, no network).
Remove it by deleting the three files it installed.

Works on macOS and Linux (bash, awk, sed, python3 for `focus-guard.sh`).

## Honest limits

- `now-drift-check.sh` tells the model to check for drift; it cannot force the model to. It makes drift
  visible every turn, which is most of the value.
- `focus-guard.sh` only sees `cd` into a path under `PROJECTS_ROOT` (default `~/Desktop/projects`, set
  the env var for your layout). Work that never does a `cd` is invisible to it.
- In `warn` mode the message goes to stderr and the command proceeds. Start there for a week, then
  switch `hook_mode` to `block` if the signal is good.

## Where this comes from

These are three files from Loadout, the Claude Code setup I run daily, redacted for general use
(personal names, voice integration, and machine paths removed). The full version is an 8-chapter guide
and a starter pack: six hooks, four rule files, worked memory entries, install and uninstall scripts, and
a year of updates. It is paid; this slice is not a trial and does not expire.

If you want the rest: https://loadout.hellomilo.app/?utm_source=hackernews&utm_medium=github-readme&utm_campaign=show-hn-2026-11
Chapter 1 of the guide is free to read there with no email.

Token-cost benchmark for your own setup (public, MIT): https://github.com/ajeenkya/loadout-benchmark
