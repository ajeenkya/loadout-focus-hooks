# Lesson Routing

How to decide where a lesson goes. Run these three questions in order. **Only write a new memory file when the lesson doesn't fit any of them.**

## The three questions

1. **Is it structural?** → in-code comment. Future-you reads it when touching the code. Zero memory cost.
   - Example: `// this ViewModifier exists to keep RootView under the compiler's type-check budget`
   - Test: would someone reading this code in 6 months need to know it? If yes, comment.

2. **Is it universal to a stack you'll keep working in** (Swift, Python, bash, etc.)? → append to `~/.claude/rules/<stack>.md`.
   - CLAUDE.md routes to it on demand. Zero ongoing context cost.
   - Test: does this apply across projects, not just this one?

3. **Is it project-specific to an existing tool/system you've already memory'd?** → append to that existing memory file.
   - One file's tokens grow by a few hundred bytes vs adding a whole new entry.
   - Test: is there already a memory entry for this domain? Update it, don't fork.

## The meta-rule

Memory entry growth should track **structural growth**, not lesson count. Lessons compound; entries shouldn't.

If MEMORY.md is growing faster than the number of distinct systems/people/projects you care about, you're routing wrong.

## When to actually create a new memory file

Only when:
- It's not code-resident (rules out #1)
- It's not stack-universal (rules out #2)
- There's no existing memory entry whose scope includes it (rules out #3)
- AND it's something future-Claude will need across sessions

If all four hold, create the file. Otherwise route to one of the three above.

## Self-check at end of substantive turns

Before writing any new memory entry, ask: "Did I run the three questions?" If no, run them now. If the answer routes elsewhere, route there instead.
