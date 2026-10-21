---
name: local-context-continue
description: Resume work on one existing .local_context/<feature_name>/ folder — read its CURRENT.md and IMPLEMENTATION_PLAN.md, agree the session's skills and rules with the user, then work the plan's tasks in order while keeping the three files true. Run by the user as local-context-continue [feature_name | free-text instructions].
argument-hint: "[feature_name] or free text naming the feature plus session rules"
disable-model-invocation: true
---

# local-context-continue

Picks up a feature created by `local-context-new` (and cleaned by `local-context-tidy`) and
carries it forward. Typical calls:

```
local-context-continue <feature_name>
local-context-continue let's continue the implementation of @.local_context/<feature_name>.
                        Mandatory skills: caveman for exploration, ponytail for code.
```

`<feature_name>` is a placeholder. The folder comes only from the user's arguments (step 1);
never look for a folder named in these examples.

The folder contract is the one `new` writes:

| File | Holds | How this skill uses it |
|---|---|---|
| `CURRENT.md` | what is true now; ends with § RESUME HERE | read first, in full; rewrite sections that stop being true |
| `IMPLEMENTATION_PLAN.md` | § START HERE, numbered § Tasks (Repo / Depends on / Anchors / **Done when**), § Blocked on a decision, § Verification commands, § Do NOT do (YAGNI) | the work list — follow it in order |
| `ARCHIVE.md` | dated history, newest first, append-only | not read unless the user asks "why"; one new entry per session, prepended |
| `BUSINESS.md` *(optional)* | the feature's business rules, no technical ones | read in full when present; the work must respect it; created (template in `new`) when the first business rule is settled |

If the project's `CLAUDE.md` / `CLAUDE.local.md` defines its own `.local_context/` rules or
per-project constraints (who runs tests, never push, approval before each change, commit style),
**those win** over this file. Read them before step 3.

## 1 — Pick the folder

Project root: `git rev-parse --show-toplevel`, else cwd. `.local_context` may be a symlink (git
worktrees) — resolve it, write through it.

- **Exact name or path** in the arguments (`<feature_name>`, `@.local_context/<feature_name>`,
  a different case or `-`/`_`, a unique prefix) → use it, say which folder matched.
- **A phrase** (a description, not a folder name) → infer the best match from
  folder names (and, if names are not enough, the first lines of each `CURRENT.md`), then confirm
  with `AskUserQuestion` (or a plain question if the agent has no such tool): inferred folder first, labelled `(Recommended)`, plus the next closest.
  Never proceed on an inference without that confirmation — continuing the wrong feature edits the
  wrong files.
- **No argument, or nothing matches** → list the subfolders (`ls -t`, most recently modified first)
  and ask with `AskUserQuestion`. It takes at most 4 options, so offer the most recent ones,
  recommend the most recently modified (say so), and print the full list in the question text so
  the user can type any other name.
- **No `.local_context/` at all** → say so and suggest `local-context-new`. Stop.

## 2 — Read the state, narrowly

Everything read is re-sent on every later turn, so load only what the work needs.

1. `CURRENT.md` in full (it is meant to be short). If it is over ~600 lines, read the head and
   § RESUME HERE, and suggest `local-context-tidy` afterwards.
2. `IMPLEMENTATION_PLAN.md`: `grep -n '^#'` for the outline, then ranged reads of § START HERE, the
   next open task(s), § Blocked on a decision, § Verification commands, § Do NOT do (YAGNI).
   `BUSINESS.md` in full, if it exists.
3. If CURRENT/plan point at a sibling folder of the same feature in another repo (container repo
   ↔ subrepo), read that one only when about to touch that repo.
4. Quick drift check: `git log --oneline -10` and `git status --short` against § START HERE. If the
   plan says a task is next but a commit already did it, or a cited SHA does not exist
   (`git cat-file -t <sha>`), report it and ask whether to fix the record first or run
   `local-context-tidy`. Do not silently pick one of two disagreeing files — say they disagree.
5. Missing file: no `IMPLEMENTATION_PLAN.md` → offer to write one from what CURRENT says (same
   template as `new`); no `CURRENT.md` → the folder is not a feature, ask.

## 3 — Agree the session setup (one `AskUserQuestion` call)

Parse the arguments first: anything the user already stated (skills, levels like `/caveman full`,
extra rules) is decided — do not ask it again, apply it.

**Skills.** Check the available-skills list for `caveman` and `ponytail` (often plugin-prefixed,
e.g. `caveman:caveman`, `ponytail:ponytail`). For each one that exists and the user did not
already decide, ask whether to use it this session (recommend yes). Skip the ones not installed
and say so in one line.

- **caveman** — for exploration, and subagent prompts and answers. **Not** for what you tell the
  user about what happened and what you are doing: that stays plain, brief, understandable
  sentences. Not for anything persisted either (commit messages, code comments, `.local_context`
  files, ticket comments): caveman itself writes those in plain prose. Code, `file:line`, SHAs,
  error strings, commands stay verbatim.
- **ponytail** — for code thinking and implementation.

Once agreed, load each with the `Skill` tool. **Subagents do not inherit loaded skills**: when a
skill is on, tell every spawned agent to call `Skill(<name>)` itself before starting.

**Rules.** State the session rules (below) in two or three lines and ask only if the user's
arguments diverge from them in a way that is unclear — e.g. "skip the log lines": for this request
only, or for the whole session?

Then post a short kickoff: folder, where it stands, the next task and its **Done when**, anything
blocked.

## 4 — Session rules

These hold for the whole session unless the user explicitly says otherwise. When the user
diverges, ask whether it is once or for the rest of the session if that is not clear.

- **Log main actions.** Before each main action, write one line starting with `▸` so the user
  can reconstruct the session without reading the code: starting/finishing a task, spawning a
  subagent, editing a group of files, running verification, updating `.local_context`,
  committing. Not for every read or grep.
  `▸ Task 4 — rewriting the mailer specs (3 files)` · `▸ Task 4 done, verification green, plan updated`
- **Follow the plan.** Work `IMPLEMENTATION_PLAN.md` tasks in order, respecting **Depends on**. A
  task is done when its **Done when** line is observably true, not when the code is written.
- **Stick to the target.** Anything the current target does not need — a neighbouring bug, a
  stale doc, a tempting refactor — stop, write it down with its evidence, and ask: now, skip, or
  later. "Later" means a new task in the plan, with the evidence, before moving on. Never fold it
  in silently; never drop it silently.
- **YAGNI.** Build what the task asks. No abstraction with one caller, no option nobody asked for.
  Respect the plan's § Do NOT do table.
- **Prove it, or ask.** Every claim about the code, a version or a behaviour comes with what proves
  it: the command and its output, the `file:line`. A bug, improvement or refactor you propose
  needs its motivation proven the same way — a guess is labelled as a guess. If it cannot be
  proven, say what would prove it, or ask.
- **Options carry a recommendation.** In `AskUserQuestion`, the recommended option goes first with
  `(Recommended)`; in prose, one line saying which and why.
- **Short and clear.** Concise, efficient, no over-explaining — but understandable to someone who
  did not watch the session.

## 5 — Per task

1. `▸` line: task number, title.
2. Read the task's anchors and prove the current state before changing anything (anchors drift).
3. Implement, within the project's rules (approval before changes, who runs tests).
4. Verify with § Verification commands. If the project says the user runs a command (e.g. specs,
   docker), hand over the exact command and wait for the result.
5. Commit only when the user asks or the project's workflow says so; never push unless told.
6. Update the record (section 6), then move to the next task. Stop and ask at a blocked task, a
   decision the plan does not settle, or a failed verification you cannot explain.

## 6 — Keep the files true

Before each write, read the exact region you are changing; after it, read it back and confirm it
is complete — a truncated plan is lost history.

- **Plan**: a finished task becomes `✅ DONE <YYYY-MM-DD> (<sha>)` and stays in place, never
  deleted; before the commit exists, mark it done-uncommitted and add the SHA after. New follow-ups
  become tasks with evidence. § START HERE matches HEAD and the next task.
- **CURRENT**: replace sections that stopped being true (never append a correction beside them);
  move the replaced prose to ARCHIVE verbatim; § RESUME HERE names the next step.
- **BUSINESS**: a business rule settled this session (whoever settled it: the user, a manager, a
  client need) goes in `BUSINESS.md`, not CURRENT — create the file from `new`'s template if
  absent. A changed rule is replaced in place and its old wording moved to ARCHIVE verbatim. A pure
  technical session leaves it untouched.
- **ARCHIVE**: one dated entry for the session, prepended newest first, proving the old content
  is intact (the second command must print nothing; then `cp` the new file into place):
  `cat <entry.md> ARCHIVE.md > <scratch>/ARCHIVE.md`
  `tail -c +$(( $(wc -c < <entry.md>) + 1 )) <scratch>/ARCHIVE.md | cmp - ARCHIVE.md`
- Never commit or push `.local_context/`.

Do this after each task and before handing off (end of session, `/compact`, `/clear`), so the next
`local-context-continue` starts from files that match `git log`.

## 7 — Hand-off

A few lines: tasks done this session (with SHAs), what is uncommitted or unpushed, what is
blocked and on which question, and the next task.
