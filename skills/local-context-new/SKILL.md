---
name: local-context-new
description: Create a new per-feature working-memory folder, .local_context/<feature_name>/, in the ICM layout, initialised from the user's description, creating .local_context/ and git-ignoring it when needed. Run by the user as local-context-new.
argument-hint: the new task is called <task name> it is about <description>
disable-model-invocation: true
---

# local-context-new

Creates `.local_context/<feature_name>/` for one piece of work. Typical call:

```
local-context-new the new task is called <task name> it is about <description and details>
```

Agent working memory in the ICM layout (`<this skill folder>/ICM.md`), one kind of content per file.
`_current/` holds what is true **now** (replaced, never corrected by appending); the plan never loses a shipped
task (marked `✅ DONE <date> (<sha>)`), and blocked work sits under § Blocked on a decision with its question,
never as a task with an invented default; `_business/` holds only business rules (scope, who gets/sees/edits
what, data, timing), never who asked; `_crm/` is written only by `local-context-code-review-mapping`. Always ICM,
never `.no_icm`. The project's `CLAUDE.md` / `CLAUDE.local.md` rules on `.local_context/` win: read them first.

## Folder layout

One folder per feature under `.local_context/`. Nested only on request (`<parent>/<sub_feature>/`: the parent's
`_current/` keeps what the subtasks share). Across repos, each repo's folder has the same name and only its own
scope; a fact is written once and pointed at elsewhere (`<path>/_current/STATE.md:<line>`, or its file).

## Steps

1. **Root**: `git rev-parse --show-toplevel`, else the cwd (not a git repo). In a worktree, `.local_context` may be
   a symlink into the main checkout (`ls -la`): write through it, never replace it with a directory.
2. **`<feature_name>`**, lowercase `snake_case`, only from the user's arguments (names here are placeholders):
   - a single token (`Some-Name`, `SomeName`) → normalised (`some_name`);
   - a phrase → a 2–4 word title naming the work; say which and why in one line;
   - never starting with `_` (ICM folders): drop leading underscores;
   - inside another feature → `.local_context/<parent>/<feature_name>/`; the parent must exist;
   - the folder exists → **stop** and ask: use it (this skill then does nothing; suggest `local-context-tidy`) or
     another name. Never overwrite.
3. `mkdir -p .local_context`.
4. **Git-ignore it, in a git repo only**: `git check-ignore -q .local_context` from the root; not ignored → append
   `.local_context/` to the root `.gitignore` (create it if missing) and tell the user: that is a tracked-file edit
   in `git status`. Not a git repo: skip, say so.
5. **Write the ICM tree** from the user's description. Formats, one call:
   `sed '/^## F: business/,$d' <this skill folder>/ICM_FORMATS.md` (add `sed -n '/^## F: business/,/^## F: map/p'` only
   when writing `_business/`). Real content, not placeholders: the goal, the scope, what is known, what is open.
   What the user did not say stays an explicit open question — never invent paths, versions or decisions. A thin
   description may give only "Task 1 — investigate/scope" with the questions it must answer.
   - `_current/STATE.md`; `_current/_decisions/STATE.md`, `_current/_questions/STATE.md` with a file and row per
     decision taken and per open question (empty tables are fine).
   - `_implementation_plan/STATE.md` and `01_<slug>.md`, plus one per further task the description sets.
   - `_archive/STATE.md` and `_archive/<YYYY_MM_DD>/1.md`, titled `folder created`, body:
     Created by `local-context-new` from: "<the user's description, verbatim>".
   - `_business/` only if the description states business rules (not for a pure bug fix or upgrade): they go
     there, not in `_current/`.
6. **Read back every file** in one call (`tail -n +1 $(find .local_context/<feature_name> -type f | sort)`),
   confirm each is complete, then report: folder path, whether `.gitignore` changed, whether `_business/` was
   created, and the first task. Never commit or push `.local_context/`.
