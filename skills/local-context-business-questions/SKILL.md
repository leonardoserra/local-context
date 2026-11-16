---
name: local-context-business-questions
description: For one feature in .local_context/<feature_name>/, check where it really stands (docs against git, code and ticket), build with the user the list of questions only the business can answer, post it bilingual on the ticket, and record the answers as business rules. Asks only what the code and docs cannot answer, always with a recommendation. Run by the user as local-context-business-questions [feature_name | free text], before a call with the decision-maker or when a feature waits on the business.
argument-hint: "[feature_name] or free text naming the feature plus context (who decides, ticket key, language)"
disable-model-invocation: true
---

# local-context-business-questions

Turns a stuck, paused or re-scoped feature into **a short list of decisions the business has to take**, each
answerable without reading code. Typical calls:

```
local-context-business-questions <feature_name>
local-context-business-questions <feature_name> — boss call on Thursday, ticket <TICKET-KEY>
```

`<feature_name>` and `<TICKET-KEY>` are placeholders: the folder and ticket come only from the arguments.

A loop with the user, not a one-shot report: the first draft is always wrong somewhere. The value is running that
loop efficiently and leaving a record nobody has to reconstruct. Outputs, in order: a state report with evidence;
the question list, approved; its translation, approved; one ticket comment per ticket (English, `---`,
translation); the record updated.

The project's `CLAUDE.md` / `CLAUDE.local.md` rules (who runs tests, approval before changes, naming,
caveman/ponytail usage, how to write `.local_context`) **win** over this file.

## 1 — Pick the feature

As `local-context-continue` § 1: a name or path → use it; a phrase → infer, confirm with `AskUserQuestion` (or a
plain question), inferred first, `(Recommended)`; nothing → folders by recency (skip `_*`), ask. A feature may
exist at several levels (container repo + subrepos): find all (`ls */.local_context/<feature>` and the root one).

**Layout check**, before reading `F` or another feature folder the run writes: `ls -d F/.no_icm F/_* F/*.md 2>/dev/null`;
`<n>` = `<this skill folder>/../local-context-new`. No flat file (`CURRENT`, `IMPLEMENTATION_PLAN`, `ARCHIVE`,
`BUSINESS`, `CRM`, `CODE_REVIEW_MAPPING` `.md`) and no `.no_icm` → ICM: read `<n>/ICM.md`. `.no_icm` and no `_`
folder → legacy: `sed -n '/^## legacy/,/^## /p' <n>/ICM_OPS.md`. Otherwise → `<n>/ICM_CONVERT.md` first.

## 2 — Read narrowly

Everything read is re-sent every later turn: read down the layers and stop when you have what you need.

1. Each level's indexes in one call, cross-repo first, the plan by section only:
   `tail -n +1 F/_current/STATE.md F/_current/_*/STATE.md F/_business/STATE.md 2>/dev/null; sed -n '/^## Blocked/,/^## [^B]/p' F/_implementation_plan/STATE.md`.
   A current state over 80 prose lines (`grep -vc '^|'`): head, status banner, open items, any "undecided /
   blocked / paused" section. Open questions are candidates; decisions and business rules are settled, never asked again. Open a
   question, decision or theme file only for a candidate it bears on.
2. The ticket (key from the current state or plan): description **and comments** (the latest status; with an
   MCP ticket tool often a separate call). Linked tickets: summary only.
3. Files the current state points to in other features: only the file or section named; never sweep "just in case".
4. The project's docs that state business rules (root `BUSINESS.md`, `DOCUMENTATION.md`, `README.md`, `CLAUDE.md`,
   `AGENTS.md`, `docs/`, `*.md` naming the domain) and other features' business rules (`.local_context/*/_business/`,
   `.local_context/*/BUSINESS.md`, no layout check): `grep -ril` the feature's business names, then only the
   matching sections. A rule another feature settled holds here too.
5. The archive only for a "why" — e.g. "was this tried before and dropped?" (step 7): `archive find`, open only
   the matches.

## 3 — Check the docs against reality

The record drifts. Before asking anyone to decide, prove what is true **today**, in **every** repo of the feature,
frontend included:

- Branch heads: `git ls-remote origin <branch>` vs the SHA the docs cite; ahead/behind
  (`git rev-list --left-right --count <default>...<branch>`).
- What users get today on the default branch, the behaviour the feature would change (`file:line`): what
  "Today:" means in the questions.
- Switches that keep it dark: feature flags, commented-out crons, env gates.
- Whether the work it depends on exists yet (`git log --since=<pause date> -- <paths>`).
- Doc statements no longer true (a DB column wiped by a nightly rebuild, a limitation an upgrade removed, a
  renamed branch).

List each drift with its evidence and ask **fix now / later / skip** — never fix silently, never pick one of two
disagreeing files silently.

## 4 — Report the state

A few plain lines with evidence (`file:line`, command, ticket comment id): what is built where, what is verified
(specs, CI, manual), what is missing, what it waits on. End with the one-line answer to "does it work?".

## 5 — Sort every open point

Candidates: the docs' open items, the ticket, what step 3 surfaced. **Answer from the record first**: the code
(today's behaviour), the feature's business rules and decisions, the project docs. Answered → not asked: tell the
user in one line with the source (`file:line`, `doc § section`); a business answer found outside the business
rules is recorded there (step 10). The rest go in exactly one bucket:

| Bucket | Test | Goes to |
|---|---|---|
| **Business** | Only the business can decide: scope, who gets/sees/edits what, data leaving the company, contract or privacy, what changes for users, release timing | the question list |
| **Developer's call** | Technical, invisible to users, or settled by "keep current behaviour" | ask the user, with your recommended answer; `decision add` |
| **Another feature** | Owned by a different feature | that feature's `.local_context` and ticket (step 7) |

Unsure whether it needs the business: **"where possible, no change to behaviour or UX"**. What stays as today goes
in a closing "kept as today unless you object" list, not as questions.

## 6 — Draft the questions

- **Group by theme**, only those that apply: Scope · Where it lives / ownership · Who (recipients, permissions) ·
  Data and security · Timing and re-runs · Release. Number `A1, A2, B1…` so answers can be quoted.
- **One decision per question**, answerable yes/no or by a pick; two answers → split it.
- **State the current answer** in italics: *Today: …* (default branch) and/or *Built: …* (the parked branch), so
  the decision-maker confirms or overrides instead of designing.
- **Conditional questions** say so: *(Only if A1 includes …)*; one that only matters under another is folded into
  it as sub-bullets (link expiry, licensing, privacy under "are external addresses allowed?").
- **Business names only**: the labels users see (grep the frontend, both languages), always the full name
  ("automatic report", "report template"), never a bare "report" where two kinds exist. No table names, classes
  or `file:line` in the question text; evidence stays in chat and `.local_context`.
- **Scope discipline**: only this feature; no wording, UI or email copy unless the feature is about them.
- Close with **"Kept as today unless you object:"**, one line each.

## 7 — Iterate with the user

Read each answer carefully; it usually mixes several moves:

- **The user answers a question** → it leaves the list. A business answer is a business rule, whoever gave it
  (step 10); a technical one, `decision add`.
- **"What is X? Real or your assumption?"** → prove it from code (`file:line`, route, guard) in two lines, then
  rephrase the question so the doubt cannot recur.
- **"No risk? Then keep as today."** → risk analysis with evidence. No new risk: "kept as today". Risk only under
  another answer: fold it into that question.
- **New vocabulary** → grep the code for the word first. Already used, especially with another meaning → say so
  with `file:line` and offer 3–5 alternatives checked the same way, recommendation first.
- **A design idea owned by another feature** → layout check on its folders, then analyse it there: what the code
  does today, whether it was tried and dropped (its `archive find`, and whether those reasons still hold), what it
  would change. Write that into its `_current/STATE.md`, its plan's § Blocked (`question add` per open point),
  pointers in its subrepo folders, its own questions for its own ticket; leave a one-paragraph note in this
  feature's `_current/STATE.md` on how it affects this one.
- **"Be clearer"** → rewrite around one concrete example of what changes for a user.

Re-show the full list each round until the user approves.

## 8 — Translate

Ask once which language the decision-maker reads (default: the project's locale); use its frontend UI labels for
every business name. The user approves it separately, before the English goes anywhere.

## 9 — Post

Only after an explicit go: one comment per ticket, English block, `---`, translated block, same structure and
numbering, no AI attribution. Read the echoed body back and note the comment id. No ticket tool or ticket → give
the text ready to paste.

## 10 — Record

In the feature's cross-repo folder and in other touched features (step 7). Read each region before writing and
back after; replaced text goes verbatim into the archive entry.

- **Business rules**: every rule settled this run (by the business, the user, or found in the docs) →
  `business rule set` under its theme, with date and ref (ticket comment id, doc); no split by who decided. A
  question it answers: `question answer`. Code impact when resumed ("changes the built code: …", "depends on A2")
  → `_current/STATE.md`, pointing at the rule.
- **Developer's calls**: `decision add` each, with evidence and code impact (legacy: § *Technical positions,
  <date>* in `CURRENT.md`).
- **Open items**: a line in `_current/STATE.md` pointing at the ticket comment id; `question add` each pending
  question, citing it. Approved drift fixes replace the stale statement, never a correction beside it.
- **Plan**: § Blocked on a decision lists the pending questions by number with the ticket ref. A dev task a
  position implies: `plan add task` only if it depends on no unanswered question, else it waits in § Blocked with
  that dependency named.
- **Archive**: one entry per touched folder, `archive add`. Never commit or push `.local_context/`.

## 11 — Hand-off

A few lines: where posted (ticket + comment id), what the business owes, rules and decisions recorded, drift
fixed, follow-ups filed elsewhere, what unblocks the feature first.

## Rules for the whole run

- **No code, no DDL, no branch or MR changes.** This skill finds decisions, never acts on them.
- **Never invent a business answer to unblock work.** A probable direction is recorded as probable, never decided.
- **Prove it.** Every claim about the code, a branch or a behaviour carries its evidence; a guess is labelled a
  guess. An empty grep is an absence only if the search would have matched.
- **Outward-facing means confirm first.** Ticket comments, documents, messages: show the final text, wait for go.
- **Every question carries a recommendation**, open ones too: first with `(Recommended)` in `AskUserQuestion`,
  one line of why in prose. Ask in rounds until nothing is open.
- **Short and clear** in chat; plain business language for the decision-maker.
