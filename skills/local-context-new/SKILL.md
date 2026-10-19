---
name: local-context-new
description: Create a new per-feature working-memory folder, .local_context/<feature_name>/, with CURRENT.md, IMPLEMENTATION_PLAN.md and ARCHIVE.md initialised from the user's description, creating .local_context/ and git-ignoring it when needed. Run by the user as local-context-new.
argument-hint: the new task is called <task name> it is about <description>
disable-model-invocation: true
---

# local-context-new

Creates `.local_context/<feature_name>/` for one piece of work. Typical call:

```
local-context-new the new task is called <task name> it is about <description and details>
```

The files are AI/agent working memory: each holds one kind of content, so a later session
can read one short file and act.

| File | Holds | Rule |
|---|---|---|
| `CURRENT.md` | what is true **now** — state, contracts, invariants, load-bearing decisions, open items, next step | replace a section when it stops being true; never append a correction |
| `IMPLEMENTATION_PLAN.md` | the ordered work: numbered tasks, each with repo, dependencies, `file:line` anchors, a **Done when** line; verification commands; a **Do NOT do (YAGNI)** table | never delete a shipped task — mark it `✅ DONE <date> (<sha>)`; blocked work goes under its own heading with the blocking question, never as a task with an invented default |
| `ARCHIVE.md` | dated history, newest entry first, append-only | never rewrite old entries |
| `BUSINESS.md` *(optional)* | the business rules of the feature: what it must do for users, clients and the company — scope, who gets/sees/edits what, data, timing. No technical rules | only when the work defines or changes business behaviour (a pure bug fix or upgrade has none); replace a rule when it changes, the old wording goes to ARCHIVE; never record who asked for a rule as a category — a rule is a rule |

If the project's `CLAUDE.md` / `CLAUDE.local.md` defines its own `.local_context/` rules, those
win over this table — read them first and follow them.

## Steps

1. **Find the project root.** `git rev-parse --show-toplevel`; if that fails, the current
   working directory is the root and the project is not a git repo.
   In a git **worktree**, `.local_context` may be a symlink into the main checkout — check with
   `ls -la`, and write through the symlink, never replace it with a directory.

2. **Derive `<feature_name>`** — lowercase `snake_case`, the rule the folder name must follow:
   - A single token (`automatic_reports`, `report-templates`, `ReportTemplates`) → normalise it
     (`report_templates`).
   - A phrase or anything with spaces ("upgrade ruby and rails to latest") → make a short title
     of 2–4 words that names the work, not the sentence (`ruby_rails_upgrade`), and say which name
     you chose and why in one line.
   - If `.local_context/<feature_name>/` already exists, **stop** and ask: use it (then this skill
     does nothing — suggest `local-context-tidy`), or pick another name. Never overwrite.

3. **Create `.local_context/`** if absent (`mkdir -p`).

4. **Git-ignore it, only in a git repo.** Check with `git check-ignore -q .local_context` from the
   root. If not ignored, append `.local_context/` to the root `.gitignore` (create the file if
   missing) and tell the user — that `.gitignore` change is a tracked-file edit they will see in
   `git status`. Not a git repo: skip this step and say so.

5. **Write the three files** from the templates below, filled from the user's description. Put
   real content in, not placeholders: the goal, the scope, what is known, what is open. Anything
   the user did not say stays as an explicit open question — do not invent file paths, versions or
   decisions. If the description is thin, the plan may hold only "Task 1 — investigate/scope" with
   the questions it must answer.
   Write `BUSINESS.md` too, only if the description states business rules (who gets, sees or
   edits what, scope, what changes for users or clients, timing); otherwise do not create it.
   Business rules go there, not in `CURRENT.md`.

6. **Read each file back** and confirm it is complete (no truncation), then report: folder path,
   whether `.gitignore` changed, whether `BUSINESS.md` was created, and the first task in the plan. Do not commit anything —
   `.local_context/` is never committed or pushed.

## Templates

`CURRENT.md`:

```markdown
# <feature_name> — CURRENT

State as of **<YYYY-MM-DD>**. Current state only; history is in `ARCHIVE.md`, the work list in
`IMPLEMENTATION_PLAN.md`.

## Goal

<one paragraph: what this work is for and what "done" means>

## Scope

- In: <...>
- Out: <...>

## Where it stands

<nothing built yet / what exists today, with file:line where known>

## Decisions

<load-bearing decisions already taken, each with who/when; "none yet" is fine>

## Open questions

<what must be answered before or during the work>

## RESUME HERE

Next: `IMPLEMENTATION_PLAN.md` § Task 1.
```

`IMPLEMENTATION_PLAN.md`:

```markdown
# <feature_name> — IMPLEMENTATION_PLAN

## START HERE — <YYYY-MM-DD>

<one short paragraph: current state, the next task, anything blocking>

## Tasks

### 1 — <task title>

- **Repo**: <repo or path>
- **Depends on**: <none | task N>
- **Anchors**: <file:line, or "to find">
- **Done when**: <observable, checkable condition>

## Blocked on a decision

<none | the question, and who answers it>

## Verification commands

<commands that prove the work, e.g. test/lint/build>

## Do NOT do (YAGNI)

| Not doing | Why |
|---|---|
```

`ARCHIVE.md`:

```markdown
## <YYYY-MM-DD> — folder created

Created by `local-context-new` from: "<the user's description, verbatim>".
```

`BUSINESS.md` (optional, also created later by `local-context-continue` or
`local-context-business-questions` when the first business rule is settled):

```markdown
# <feature_name> — BUSINESS

Business rules as of **<YYYY-MM-DD>**: what this feature must do for users, clients and the
company. No technical rules (those are in `CURRENT.md`). A rule that changes is replaced here; the
old wording goes to `ARCHIVE.md`.

## <theme, e.g. Scope · Who · Data · Timing>

- <the rule, in business language> — <YYYY-MM-DD>; <ref: ticket comment, doc, call — if any>
```
