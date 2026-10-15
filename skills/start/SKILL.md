---
name: start
description: Create a new .local_context/<feature_name>/ folder (as /local-context:new does) and immediately resume work on it (as /local-context:continue does) — one command from idea to first task. Run by the user as /local-context:start.
argument-hint: the new task is called <task name> it is about <description> [plus session rules]
disable-model-invocation: true
---

# local-context:start

`new` followed by `continue`, in one call:

```
/local-context:start the new task is called <task name> it is about <description and details>
```

The two sibling skills are the source of truth — this file only joins them. Read them now and
follow them, rather than working from memory:

- `${CLAUDE_SKILL_DIR}/../new/SKILL.md`
- `${CLAUDE_SKILL_DIR}/../continue/SKILL.md`

## 1 — Split the arguments

`$ARGUMENTS` may carry two things: the feature description (name, goal, details) and session
setup (skills like caveman / ponytail, levels like `/caveman full`, extra session rules). The
description feeds `new`; the setup feeds `continue` § 3, where anything already stated is
applied without asking again. If a sentence could be either, treat it as description — it ends
up in `CURRENT.md`, where it is visible and easy to correct.

## 2 — Run `new`

Follow `new` steps 1–2 to find the root and derive `<feature_name>`. Then:

- **`.local_context/<feature_name>/` already exists** → skip the rest of `new`, never touch its
  files, say in one line that the folder exists and is being continued, and run `continue` on it
  in full from § 2 — reading its files and checking them for drift, since it has history.
- **It does not exist** → follow `new` steps 3–6, end with `new`'s report in one or two lines
  (folder, whether `.gitignore` changed, first task), then go to § 3.

## 3 — Run `continue` on the new folder

Follow `continue` from § 2, with the folder fixed to the one just created:

- Skip § 1 — the folder is known.
- § 2: the files were just written and read back, so do not read them again; skip the drift check
  (there is no history to drift from).
- § 3 onwards as written: agree skills and rules, post the kickoff, work Task 1.

A new plan often starts with an investigate/scope task whose answers reshape the rest. When that
task closes, rewrite the plan's later tasks from what it found, show the user the new task list,
and wait for a go before building.
