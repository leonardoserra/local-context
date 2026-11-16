---
name: local-context-start
description: Create a new .local_context/<feature_name>/ folder (as local-context-new does) and immediately resume work on it (as local-context-continue does) — one command from idea to first task. Run by the user as local-context-start.
argument-hint: the new task is called <task name> it is about <description> [plus session rules]
disable-model-invocation: true
---

# local-context-start

`new` followed by `continue`, in one call:

```
local-context-start the new task is called <task name> it is about <description and details>
```

The sibling skills are the source of truth; this file only joins them. Read and follow
`<this skill folder>/../local-context-new/SKILL.md` and `<this skill folder>/../local-context-continue/SKILL.md`.

1. **Split the arguments**: the feature description (name, goal, details) feeds `new`; session setup (skills like
   caveman / ponytail, levels like `/caveman full`, extra rules) feeds `continue` § 3, applied without asking again.
   A sentence that could be either is description: it lands in `_current/STATE.md`, visible and easy to correct.
2. **Run `new`** steps 1–2 (root, `<feature_name>`). Then:
   - the folder **exists** → never touch its files; say in one line it is being continued, and run `continue` in
     full from its layout check (it may be a flat pre-3.0.0 folder);
   - it **does not** → `new` steps 3–6, its report in one or two lines (folder, `.gitignore` changed, first task).
3. **Run `continue`** on the new folder from § 2: skip § 1 and its layout check (`new` wrote ICM; read
   `<this skill folder>/../local-context-new/ICM.md`), do not re-read the files just read back, skip the drift
   check but note `git rev-parse --short HEAD` as the session's `<start>`; § 3 onwards as written.

A first investigate/scope task often reshapes the rest: when it closes, rewrite the later tasks from what it
found, show the new task list, and wait for a go before building.
