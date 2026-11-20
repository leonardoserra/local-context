---
name: local-context-save
description: Save the current session into its .local_context/<feature_name>/ folder before a /clear, a restart or a break — tasks done or in progress, decisions, questions, new tasks, business rules, uncommitted work — and rewrite § RESUME HERE as the exact next step, so local-context-continue resumes cheaply. Writes no code, commits nothing. Run by the user as local-context-save [feature_name | free text].
argument-hint: "[feature_name] or free text naming the feature"
disable-model-invocation: true
---

# local-context-save

Writes what this session implemented, decided, learned or left open into the feature folder `F`, so the session
can be cleared and `local-context-continue <feature_name>` picks up from the files alone. Typical calls:

```
local-context-save
local-context-save <feature_name>
local-context-save I need to restart, save the context so I can continue after
```

`<c>` = `<this skill folder>/../local-context-continue`, `<n>` = `<this skill folder>/../local-context-new`. The
operations named below are sections of `<n>/ICM_OPS.md` (`sed -n '/^## <op>/,/^## /p'`), read when the step runs;
formats are in `<n>/ICM_FORMATS.md`, by section; `<s>` = the session scratchpad, else
`/tmp/local-context-save-<date>/`. The project's `CLAUDE.md` / `CLAUDE.local.md` rules on
`.local_context/` win over this file.

Never edit code, commit, stash or push. Write only facts from this conversation and git, never a guess; do not copy
what `git log` already says, cite the SHA.

## 1 — Pick the folder

The feature this session already worked (a `local-context-continue`, `-start` or `-new` run, or its files edited)
→ use it, say so. Otherwise, or when the arguments name another one: `sed -n '/^## 1 — Pick the folder/,/^## 2/p'
<c>/SKILL.md` and follow it, layout check included. Several candidates → ask, never guess.

Same-name folders in other repos, a parent or sub-features: each one this session touched is saved too, each with
only its own repo's facts, pointing at the others (continue § 6, Pointers, not copies).

## 2 — Gather

Read the indexes in one call (ICM.md; legacy: § legacy's Read); skip whatever this session already read and did not
change. Then only the pieces the session changed. Per repo touched, one call:
`git branch --show-current; git status --short; git log --oneline <start>..HEAD`. `<start>` = the end of the newest
archive row written this session; else the HEAD continue noted; else the end of the last archive row's Commits; else
`git log --oneline -10`. Plus `git diff --stat` for uncommitted work.

From the conversation and that output, list:

- tasks finished (with SHA, or uncommitted), started, blocked and on what;
- decisions taken, questions opened or answered, by whom;
- new work found and agreed as later, with its evidence; YAGNI items agreed;
- business rules stated this session (by the user or someone they quote);
- session rules agreed in continue § 3 (skills, levels, extra rules), if any;
- half-done edits: file, what is done, what remains; the command that was about to run.

Nothing new since the last save → say so and skip to step 4.

## 3 — Write

`sed -n '/^## 6 — Keep the files true/,/^## 7/p' <c>/SKILL.md` and follow it, plus:

1. **Plan**: a blocked task → `⏸ blocked`, with § Blocked on a decision. YAGNI items agreed: rows in § Do NOT do
   (YAGNI). § START HERE: heading date = today, the branch, `git rev-parse --short HEAD` at save time, the next
   task, "uncommitted work: see § RESUME HERE".
2. **Current state**: update the "State as of <date>" line. The old § RESUME HERE and § START HERE text counts as
   replaced text: verbatim into the archive entry.
3. **§ RESUME HERE**, rewritten so a fresh session needs no code beyond the anchors:
   - the next task (`_implementation_plan/<NN>_<slug>.md`) and the exact step inside it;
   - `file:line` anchors for that step;
   - half-done edits: what is done, what remains;
   - the next command to run, and who runs it;
   - only what git cannot show (never copy `git status`): which uncommitted file belongs to which task, and whether
     it is intended or half-done;
   - session rules to re-apply (continue § 3 takes them as already stated), and anything the user said to remember.
4. **Archive** (`archive add`; legacy: § legacy's prepend): what was done, decided and learned, plus the replaced
   text verbatim. One entry per save or session end; a later save, or continue's own entry, covers only what came
   after the last entry written this session. Existing entries are never edited.
5. **Check**: `state check` (ICM only) prints nothing. A mismatch this run caused → fix it; over 80 prose lines →
   report it and suggest `local-context-tidy`, do not cut. `git status --short` shows the project tree unchanged
   outside `.local_context/`.

## 4 — Report

A few lines: the files changed per folder, the § RESUME HERE text as written, then:
"Saved. You can clear the session now; resume with `local-context-continue <feature_name>`." — the folder's real
name in place of `<feature_name>`, so the command can be pasted as is.
