---
name: local-context-continue
description: Resume one existing .local_context/<feature_name>/ folder — read its state indexes and only the files the next task needs, agree the session's skills and rules with the user, then work the plan's tasks in order while keeping the record true. Run by the user as local-context-continue [feature_name | free-text instructions].
argument-hint: "[feature_name] or free text naming the feature plus session rules"
disable-model-invocation: true
---

# local-context-continue

Carries forward a feature made by `local-context-new`. Typical calls:

```
local-context-continue <feature_name>
local-context-continue let's continue @.local_context/<feature_name>. Mandatory skills: caveman for exploration, ponytail for code.
```

`<feature_name>` is a placeholder: the folder comes only from the arguments, never from these examples. The
project's `CLAUDE.md` / `CLAUDE.local.md` rules on `.local_context/` and its constraints (who runs tests, never push,
approval before each change, commit style) **win** over this file; read them before step 3.

## 1 — Pick the folder

Root: `git rev-parse --show-toplevel`, else cwd. `.local_context` may be a symlink (worktrees): resolve it, write
through it.

- **A name or path** (any case, `-`/`_`, a unique prefix, `<parent>/<sub_feature>`) → use it, say which matched.
- **A phrase** → infer from folder names (else each one's current-state head), then confirm with `AskUserQuestion`
  (a plain question without it): inferred folder first, `(Recommended)`, plus the next closest. Never proceed on an
  unconfirmed inference — the wrong feature means the wrong files edited.
- **Nothing given or matched** → `ls -t` (names starting with `_` skipped) and ask with `AskUserQuestion`: up to 4
  options, the most recent first and recommended (say so), the full list in the question text.
- **No `.local_context/`** → say so, suggest `local-context-new`, stop.

**Layout check**, before reading `F` or another feature folder the run writes: `ls -d F/.no_icm F/_* F/*.md 2>/dev/null`;
`<n>` = `<this skill folder>/../local-context-new`. No flat file (`CURRENT`, `IMPLEMENTATION_PLAN`, `ARCHIVE`,
`BUSINESS`, `CRM`, `CODE_REVIEW_MAPPING` `.md`) and no `.no_icm` → ICM: read `<n>/ICM.md`. `.no_icm` and no `_`
folder → legacy: `sed -n '/^## legacy/,/^## /p' <n>/ICM_OPS.md`. Otherwise → `<n>/ICM_CONVERT.md` first.

## 2 — Read the state, narrowly

Everything read is re-sent on every later turn: read down the layers and stop when you have what you need.

1. The indexes, in one call. A current state over 80 prose lines (`grep -vc '^|'`): its head and § RESUME HERE
   only; suggest `local-context-tidy` afterwards.
2. The next task's file. A decision, question or business theme file only when that task touches it. A same-name
   folder in another repo only when about to touch that repo; a sub-feature's parent only for the shared part, by
   the file or `path:line` a pointer names.
3. Drift: `git log --oneline -10` and `git status --short` against § START HERE and the statuses. A task the plan
   calls next already committed, or a cited SHA missing (`git cat-file -t <sha>`) → report it, ask: fix the record
   first, or run `local-context-tidy`. Two files disagree → say so, never pick one silently. Note
   `git rev-parse --short HEAD`: the session's `<start>`.
4. No plan → offer one from the current state (ICM_FORMATS.md § F: plan); no current state →
   not a feature, ask.

## 3 — Agree the session setup (one `AskUserQuestion` call)

What the arguments already state (skills, levels like `/caveman full`, extra rules) is decided: apply it, do not
ask again.

**Skills.** In the available-skills list, look for `caveman` and `ponytail` (often prefixed, e.g.
`caveman:caveman`). For each one installed and not yet decided, ask whether to use it this session (recommend yes);
say in one line which are not installed.

- **caveman** — for exploration, and subagent prompts and answers. **Not** for what you tell the user about what
  happened and what you are doing: that stays plain, brief, understandable sentences. Not for anything persisted
  either (commit messages, code comments, `.local_context` files, ticket comments): caveman itself writes those in
  plain prose. Code, `file:line`, SHAs, error strings, commands stay verbatim.
- **ponytail** — for code thinking and implementation.

Load each agreed one with the `Skill` tool. **Subagents do not inherit loaded skills**: tell every spawned agent to
call `Skill(<name>)` itself before starting.

**Rules.** State the session rules (below) in two or three lines; ask only where the arguments diverge from them
unclearly — e.g. "skip the log lines": this request only, or the whole session?

Then a short kickoff: folder, where it stands, the next task and its **Done when**, anything blocked.

## 4 — Session rules

For the whole session unless the user says otherwise; when the user diverges, ask whether once or for good if
that is not clear.

- **Log main actions.** Before each, one line starting with `▸`, so the user can follow without reading the code:
  starting/finishing a task, spawning a subagent, editing a group of files, verifying, updating `.local_context`,
  committing. Not for every read or grep.
  `▸ Task 4 — rewriting the mailer specs (3 files)` · `▸ Task 4 done, verification green, plan updated`
- **Follow the plan.** Tasks in the table's order, respecting the Depends on column. A task is done when its
  **Done when** is observably true, not when the code is written.
- **Stick to the target.** Anything the target does not need — a neighbouring bug, a stale doc, a tempting refactor
  — stop, write it down with its evidence, and ask: now, skip, or later. Later = a new task (`plan add task`) with
  the evidence, before moving on. Never fold it in or drop it silently.
- **YAGNI.** Build what the task asks: no abstraction with one caller, no option nobody asked for. Respect § Do NOT do.
- **Prove it, or ask.** Every claim about the code, a version or a behaviour comes with its proof: the command and
  its output, the `file:line`. A proposed fix, improvement or refactor needs its motivation proven the same way; a
  guess is labelled a guess. Unprovable → say what would prove it, or ask.
- **Options carry a recommendation.** First and `(Recommended)` in `AskUserQuestion`; one line of which and why in prose.
- **Short and clear.** Concise, but understandable to someone who did not watch the session.

## 5 — Per task

1. `▸` line: task number, title.
2. Read the task's anchors and prove the current state before changing anything (anchors drift).
3. Implement, within the project's rules (approval before changes, who runs tests).
4. Verify with § Verification commands. If the project says the user runs a command (specs, docker), hand over
   the exact command and wait for the result.
5. Commit only when the user asks or the project's workflow says so; never push unless told.
6. Update the record (step 6), then the next task. Stop and ask at a blocked task, a decision the plan does not
   settle, or a failed verification you cannot explain.

## 6 — Keep the files true

Read the region before each write and read it back after — a truncated plan is lost history. Text a change
replaces goes verbatim into the session's archive entry.

- **Plan**: `plan mark` a finished task `✅ DONE <date> (<sha>)`, or `done-uncommitted <date>` until committed;
  never delete a task. Follow-ups: `plan add task`, with evidence. § START HERE matches HEAD and the next task.
- **Current state**: replace what stopped being true, never append a correction; § RESUME HERE names the next step.
  `decision add`, `question add`, `question answer` as they arise.
- **Business**: a business rule settled this session, whoever settled it (the user, a manager, a client need) →
  `business rule set`, never the current state. A pure technical session leaves it untouched.
- **Pointers, not copies**: a fact owned by the parent or another repo's folder is written there once and cited by
  file or `path:line`; fix the pointers whose lines moved, in the same session.
- **Archive**: one entry per session, `archive add`. Never commit or push `.local_context/`.

Do this after each task and before handing off (end of session, `/compact`, `/clear`), so the next session starts
from files that match `git log`.

## 7 — Hand-off

A few lines: tasks done this session (with SHAs), what is uncommitted or unpushed, what is blocked and on which
question, and the next task.
